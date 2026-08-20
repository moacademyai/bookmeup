import Foundation
import PhoneNumberKit

/// The one place where phone numbers are parsed, validated, normalised and compared.
///
/// Parsing is backed by Google's libphonenumber metadata through PhoneNumberKit, so
/// trunk prefixes and number lengths come from real per-country data instead of
/// hand-written string surgery. Everything written into the client base goes through
/// `e164(_:region:)`, and duplicates are decided by `comparisonKey(_:region:)`.
enum PhoneFormat {
    /// The salon works in Lithuania, so the picker starts there.
    nonisolated static let defaultRegion = "LT"

    private static let utility = PhoneNumberUtility()

    // MARK: - Parsing

    /// The parsed number, or `nil` when the input cannot be a real number.
    ///
    /// Input starting with `+` carries its own country code and is read independently
    /// of `region`.
    static func parse(_ raw: String, region: String = defaultRegion) -> PhoneNumber? {
        for candidate in candidates(raw) {
            if let number = try? utility.parse(candidate, withRegion: region, ignoreType: true) {
                return number
            }
        }
        return nil
    }

    /// `+37065539948` — the only form written into a client record.
    static func e164(_ raw: String, region: String = defaultRegion) -> String? {
        guard let number = parse(raw, region: region) else { return nil }
        return utility.format(number, toType: .e164)
    }

    /// Readable international form, used everywhere a number is shown.
    static func display(_ raw: String, region: String = defaultRegion) -> String {
        guard let number = parse(raw, region: region) else { return raw }
        return utility.format(number, toType: .international)
    }

    static func isValid(_ raw: String, region: String = defaultRegion) -> Bool {
        e164(raw, region: region) != nil
    }

    /// Decides whether two numbers belong to the same person.
    ///
    /// Valid numbers compare on their E.164 form, so `+37065539948`, `865539948`,
    /// `065539948` and `65539948` are one client. Anything unparsable falls back to
    /// its last digits so older records still match.
    static func comparisonKey(_ raw: String, region: String = defaultRegion) -> String {
        if let normalized = e164(raw, region: region) { return normalized }
        let digits = raw.filter(\.isNumber)
        return digits.count > 8 ? String(digits.suffix(8)) : digits
    }

    /// Country of a fully international number, when the calling code names exactly one.
    ///
    /// Shared codes such as `+1` are left alone rather than guessed.
    static func detectedCountry(_ raw: String) -> PhoneCountry? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("+"), let number = parse(trimmed) else { return nil }
        let code = Int(number.countryCode)
        let matches = countries.filter { $0.dialCode == code }
        return matches.count == 1 ? matches[0] : nil
    }

    /// People often type a trunk zero their country does not actually use, so the
    /// stripped form is tried as well.
    private static func candidates(_ raw: String) -> [String] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        var list = [trimmed]
        let digits = trimmed.filter(\.isNumber)
        if !trimmed.hasPrefix("+"), digits.hasPrefix("0") {
            let stripped = String(digits.drop(while: { $0 == "0" }))
            if !stripped.isEmpty { list.append(stripped) }
        }
        return list
    }

    // MARK: - Countries

    /// Every country the picker offers: the salon's own region and neighbours first,
    /// then the rest alphabetically.
    static let countries: [PhoneCountry] = {
        let pinned = ["LT", "LV", "EE", "PL", "GB", "IE", "NO", "SE", "DE", "ES"]
        let all: [PhoneCountry] = utility.allCountries().compactMap { region in
            guard let code = utility.countryCode(for: region) else { return nil }
            return PhoneCountry(region: region, dialCode: Int(code))
        }
        let head = pinned.compactMap { region in all.first { $0.region == region } }
        let tail = all
            .filter { !pinned.contains($0.region) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return head + tail
    }()

    static func country(for region: String) -> PhoneCountry? {
        countries.first { $0.region == region }
    }

    static var defaultCountry: PhoneCountry {
        country(for: defaultRegion) ?? PhoneCountry(region: defaultRegion, dialCode: 370)
    }
}
