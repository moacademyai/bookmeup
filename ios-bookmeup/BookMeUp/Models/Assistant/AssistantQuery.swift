import Foundation

/// A window of time the client asked for, e.g. "šiandien nuo 15:00 iki 18:00".
nonisolated struct AssistantTimeWindow: Hashable {
    /// The day the window belongs to.
    var day: Date
    /// Minutes from midnight. `nil` means the client named a day but not an hour.
    var startMinute: Int?
    var endMinute: Int?

    func contains(_ date: Date) -> Bool {
        guard AppDate.isSameDay(date, day) else { return false }
        let minute = AppDate.minuteOfDay(date)
        if let startMinute, minute < startMinute { return false }
        if let endMinute, minute > endMinute { return false }
        return true
    }

    var text: String {
        guard let startMinute else { return day.relativeDayText }
        let start = AppDate.timeText(minuteOfDay: startMinute)
        guard let endMinute else { return "\(day.relativeDayText) nuo \(start)" }
        return "\(day.relativeDayText) \(start)–\(AppDate.timeText(minuteOfDay: endMinute))"
    }
}

/// What the client asked for, in structured form.
///
/// The assistant never reasons over raw text: text is resolved into this once, and every
/// search, refinement and follow-up works on the structure. That is what makes it
/// possible to swap the local resolver for a server-side model later — the model would
/// produce exactly this type and nothing downstream would change.
nonisolated struct AssistantQuery: Hashable {
    /// Exactly what the client typed, kept for the transcript and for a future backend.
    var text: String
    var category: ServiceCategory?
    /// A service name mentioned in the request, e.g. "kirpimas".
    var serviceTerm: String?
    var window: AssistantTimeWindow?
    /// Upper price limit in euros.
    var maxPrice: Double?
    /// Minimum rating, e.g. 4.8.
    var minRating: Double?
    /// The client asked for the cheapest option rather than the best overall.
    var prefersCheapest: Bool = false
    /// The client asked for something close by.
    var prefersNearby: Bool = false
    /// The client asked for the best-rated option.
    var prefersTopRated: Bool = false
    /// The client pointed at someone they already know — a favorite or a past visit.
    var prefersKnownProviders: Bool = false
    /// The client explicitly wants something new.
    var prefersNovelty: Bool = false
    /// How many results to return. Grows when the client asks to see more.
    var limit: Int = 3

    init(text: String) {
        self.text = text
    }

    /// A short line describing what was understood, shown above the results so the
    /// client can see the assistant's reading of their request and correct it.
    var understandingText: String {
        var parts: [String] = []
        if let category { parts.append(category.title) }
        if let serviceTerm, category == nil { parts.append(serviceTerm.capitalizedFirst) }
        if let window { parts.append(window.text) }
        if let maxPrice { parts.append("iki \(Int(maxPrice)) €") }
        if let minRating { parts.append("nuo \(NumberText.oneDecimal(minRating)) ★") }
        if prefersNearby { parts.append("netoli") }
        if prefersCheapest { parts.append("pigiausia") }
        if prefersTopRated { parts.append("geriausiai vertinama") }
        if prefersKnownProviders { parts.append("pažįstami specialistai") }
        return parts.joined(separator: " · ")
    }

    var hasAnyConstraint: Bool { !understandingText.isEmpty }
}

/// A follow-up the client can tap instead of typing a new sentence.
///
/// Each one is a transformation of the previous query, which keeps the conversation
/// stateful without the client having to repeat what they already said.
nonisolated enum AssistantRefinement: String, Identifiable, Hashable, CaseIterable {
    case closer
    case cheaper
    case betterRated
    case more

    var id: String { rawValue }

    var title: String {
        switch self {
        case .closer: "Arčiau manęs"
        case .cheaper: "Pigiau"
        case .betterRated: "Tik 4,8+"
        case .more: "Parodyk dar"
        }
    }

    var symbolName: String {
        switch self {
        case .closer: "location"
        case .cheaper: "eurosign.circle"
        case .betterRated: "star"
        case .more: "plus.magnifyingglass"
        }
    }

    /// Applies this refinement to the query it was offered for.
    func applied(to query: AssistantQuery, cheapestShown: Double?) -> AssistantQuery {
        var refined = query
        switch self {
        case .closer:
            refined.prefersNearby = true
        case .cheaper:
            refined.prefersCheapest = true
            // Anchor below what the client has already seen, so "pigiau" really means
            // cheaper than these results and not just the same list again.
            if let cheapestShown {
                refined.maxPrice = min(query.maxPrice ?? .greatestFiniteMagnitude, cheapestShown - 0.01)
            }
        case .betterRated:
            refined.minRating = max(query.minRating ?? 0, 4.8)
        case .more:
            refined.limit = query.limit + 3
        }
        return refined
    }
}
