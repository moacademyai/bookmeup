import Foundation

/// A country in the phone number picker: flag, local name and calling code.
nonisolated struct PhoneCountry: Identifiable, Hashable, Sendable {
    /// ISO 3166-1 alpha-2 region, e.g. "LT".
    let region: String
    /// International calling code without the plus, e.g. 370.
    let dialCode: Int

    var id: String { region }

    var dialText: String { "+\(dialCode)" }

    /// Regional indicator symbols built from the region letters.
    var flag: String {
        var result = ""
        for scalar in region.uppercased().unicodeScalars {
            guard let indicator = UnicodeScalar(127_397 + scalar.value) else { continue }
            result.unicodeScalars.append(indicator)
        }
        return result
    }

    /// Country name in Lithuanian, matching the rest of the interface.
    var name: String {
        Locale(identifier: "lt_LT").localizedString(forRegionCode: region) ?? region
    }
}
