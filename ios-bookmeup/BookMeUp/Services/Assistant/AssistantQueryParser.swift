import Foundation

/// Turns a sentence a client typed into an `AssistantQuery`.
///
/// This is a deterministic, on-device resolver — vocabulary and patterns, not a language
/// model. It is honest about that: it only claims to understand what it can actually
/// extract, and `AssistantQuery.understandingText` shows the client exactly that much.
///
/// When the assistant backend is connected, the model produces the same `AssistantQuery`
/// and this file becomes the offline fallback. Nothing downstream has to change.
nonisolated enum AssistantQueryParser {

    static func parse(_ text: String) -> AssistantQuery {
        let lowered = text.lowercased()
        var query = AssistantQuery(text: text.trimmingCharacters(in: .whitespacesAndNewlines))

        query.category = category(in: lowered)
        query.serviceTerm = serviceTerm(in: lowered)
        query.window = window(in: lowered)
        query.maxPrice = maxPrice(in: lowered)
        query.minRating = minRating(in: lowered)
        query.prefersCheapest = contains(lowered, ["pigiaus", "pigiau", "kuo pigiau"])
        query.prefersNearby = contains(lowered, ["netoli", "aplink mane", "šalia", "arčiau", "arčiausi", "netoliese"])
        query.prefersTopRated = contains(lowered, ["geriausiai vertin", "geriausias", "geriausia", "aukščiausiai vertin"])
        query.prefersKnownProviders = contains(lowered, ["mėgstam", "mano meistr", "kaip praeit", "paskutinį kartą", "vėl pas", "ten, kur"])
        query.prefersNovelty = contains(lowered, ["kažką naujo", "ka nors naujo", "išbandyti"])
        return query
    }

    // MARK: - Category

    /// Vocabulary per category. Ordered from the most specific industry to the broadest,
    /// so "veido valymas" lands in beauty and not in home.
    private static let categoryVocabulary: [(ServiceCategory, [String])] = [
        (.nails, ["nag", "manikiūr", "manikiur", "pedikiūr", "pedikiur"]),
        (.massage, ["masaž", "masaz"]),
        (.hair, ["kirp", "plauk", "barber", "barzd", "šukuos", "sukuos", "dažym", "fade", "kirpėj", "kirpej"]),
        (.beauty, ["kosmetolog", "veido", "antak", "blakstien", "depiliac", "grož", "groz"]),
        (.wellness, ["odontolog", "dantų", "dantu", "fizioterap", "sveikat", "gydytoj", "terapeut"]),
        (.fitness, ["treniruot", "pilates", "joga", "sport", "trener"]),
        (.home, ["florist", "puokšt", "puokst", "gėli", "geli", "namams"])
    ]

    private static func category(in text: String) -> ServiceCategory? {
        for (category, keywords) in categoryVocabulary where contains(text, keywords) {
            return category
        }
        return nil
    }

    /// Vocabulary that also names a concrete service, used to pick the right item from a
    /// provider's catalogue rather than just the cheapest one.
    private static let serviceVocabulary: [String: String] = [
        "kirpim": "kirpimas",
        "apsikirp": "kirpimas",
        "barzd": "barzda",
        "masaž": "masažas",
        "manikiūr": "manikiūras",
        "pedikiūr": "pedikiūras",
        "antak": "antakiai",
        "veido valym": "veido valymas",
        "dažym": "dažymas",
        "treniruot": "treniruotė"
    ]

    private static func serviceTerm(in text: String) -> String? {
        for (needle, term) in serviceVocabulary where text.contains(needle) {
            return term
        }
        return nil
    }

    // MARK: - Time

    private static func window(in text: String) -> AssistantTimeWindow? {
        guard let day = day(in: text) else {
            // An hour range with no named day means today.
            guard let range = hourRange(in: text) else { return nil }
            return AssistantTimeWindow(day: Date(), startMinute: range.start, endMinute: range.end)
        }
        if let range = hourRange(in: text) {
            return AssistantTimeWindow(day: day, startMinute: range.start, endMinute: range.end)
        }
        if let part = partOfDay(in: text) {
            return AssistantTimeWindow(day: day, startMinute: part.start, endMinute: part.end)
        }
        return AssistantTimeWindow(day: day, startMinute: nil, endMinute: nil)
    }

    private static func day(in text: String) -> Date? {
        if text.contains("šiandien") || text.contains("siandien") { return Date() }
        if text.contains("rytoj") { return AppDate.time(9, 0, dayOffset: 1) }
        if text.contains("poryt") { return AppDate.time(9, 0, dayOffset: 2) }
        if text.contains("kitai savaitei") || text.contains("kitą savaitę") || text.contains("kita savaite") {
            return AppDate.time(9, 0, dayOffset: 7)
        }
        for (index, names) in weekdayNames.enumerated() where contains(text, names) {
            return nextDate(isoWeekday: index + 1)
        }
        return nil
    }

    /// Stems, so "šeštadienį", "šeštadienis" and "šeštadienio" all match.
    private static let weekdayNames: [[String]] = [
        ["pirmadien"], ["antradien"], ["trečiadien", "treciadien"], ["ketvirtadien"],
        ["penktadien"], ["šeštadien", "sestadien"], ["sekmadien"]
    ]

    private static func nextDate(isoWeekday: Int) -> Date {
        let today = AppDate.isoWeekday(of: Date())
        var offset = isoWeekday - today
        if offset <= 0 { offset += 7 }
        return AppDate.time(9, 0, dayOffset: offset)
    }

    /// Named parts of the day, in the sense people use them when booking.
    private static func partOfDay(in text: String) -> (start: Int, end: Int)? {
        if text.contains("po darbo") { return (17 * 60, 20 * 60) }
        if text.contains("per pietus") || text.contains("pietų metu") { return (11 * 60 + 30, 14 * 60) }
        if text.contains("vakare") || text.contains("vakarui") || text.contains("vakaro") { return (17 * 60, 21 * 60) }
        if text.contains("ryte") || text.contains("rytui") || text.contains("iš ryto") { return (8 * 60, 11 * 60) }
        if text.contains("dieną") || text.contains("per dieną") { return (11 * 60, 16 * 60) }
        return nil
    }

    /// "nuo 15:00 iki 18:00", "nuo 15 iki 18", "po 17".
    private static func hourRange(in text: String) -> (start: Int, end: Int?)? {
        if let match = capture(#"nuo\s*(\d{1,2})(?::(\d{2}))?\s*(?:val\.?)?\s*iki\s*(\d{1,2})(?::(\d{2}))?"#, in: text),
           let startHour = Int(match[1] ?? "") {
            let startMinute = Int(match[2] ?? "0") ?? 0
            guard let endHour = Int(match[3] ?? "") else { return nil }
            let endMinute = Int(match[4] ?? "0") ?? 0
            return (startHour * 60 + startMinute, endHour * 60 + endMinute)
        }
        if let match = capture(#"(?:po|nuo)\s*(\d{1,2})(?::(\d{2}))?\s*(?:val\.?)?"#, in: text),
           let hour = Int(match[1] ?? ""), hour <= 23 {
            let minute = Int(match[2] ?? "0") ?? 0
            return (hour * 60 + minute, nil)
        }
        return nil
    }

    // MARK: - Price and rating

    /// "iki 30 €", "iki 50", "30 eurų".
    private static func maxPrice(in text: String) -> Double? {
        if let match = capture(#"iki\s*(\d{1,4})(?:[.,](\d{1,2}))?\s*(?:€|eur|e\b)?"#, in: text),
           let whole = Double(match[1] ?? "") {
            // A number after "iki" is a price only when it is not an hour, which the
            // time patterns already claimed.
            if text.contains("iki \(match[1] ?? ""):") { return nil }
            let fraction = Double(match[2] ?? "0") ?? 0
            return whole + fraction / 100
        }
        return nil
    }

    /// "4,8+", "bent 4.8", "4,8 ★".
    private static func minRating(in text: String) -> Double? {
        guard let match = capture(#"(\d)[.,](\d)\s*(?:\+|★|\*|žvaig|zvaig|įvertinim|ivertinim)?"#, in: text),
              let whole = Double(match[1] ?? ""), let decimal = Double(match[2] ?? "") else { return nil }
        let value = whole + decimal / 10
        // Ratings live between 1 and 5; anything else in this shape is a price.
        guard value >= 1, value <= 5 else { return nil }
        return value
    }

    // MARK: - Helpers

    private static func contains(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }

    /// Returns the capture groups of the first match, or `nil`. Index 0 is the whole match.
    private static func capture(_ pattern: String, in text: String) -> [String?]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else { return nil }
        return (0..<match.numberOfRanges).map { index in
            guard let range = Range(match.range(at: index), in: text) else { return nil }
            return String(text[range])
        }
    }
}
