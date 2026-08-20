import Foundation

/// What is already known about a client before the create form opens.
///
/// A search that found nobody hands its text over here, so the specialist never types
/// the same name or number twice.
nonisolated struct NewClientPrefill: Identifiable, Hashable {
    let id = UUID()
    var firstName: String = ""
    var lastName: String = ""
    var phone: String = ""

    /// Routes a search query into the right field: digits become a phone number,
    /// words become a name.
    static func from(query: String) -> NewClientPrefill {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return NewClientPrefill() }

        let digits = trimmed.filter(\.isNumber)
        let hasLetters = trimmed.contains(where: \.isLetter)
        if !hasLetters, digits.count >= 5 {
            return NewClientPrefill(phone: trimmed)
        }

        let parts = trimmed.split(separator: " ", maxSplits: 1).map(String.init)
        return NewClientPrefill(
            firstName: parts.first ?? trimmed,
            lastName: parts.count > 1 ? parts[1] : ""
        )
    }
}
