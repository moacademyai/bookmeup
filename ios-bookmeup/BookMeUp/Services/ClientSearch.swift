import Foundation

nonisolated extension Client {
    /// Forgiving multi-token search over the client record.
    ///
    /// Every token must match something: a text token is checked against the first
    /// name, the last name and the full name; a digits-only token is checked against
    /// the phone number, so trailing digits are enough. That makes "Kipras 948" find
    /// Kipras Adomaitis whose number ends in 948, and "948" alone works too.
    func matches(query: String) -> Bool {
        let tokens = query
            .split(whereSeparator: { $0 == " " || $0 == "," })
            .map(String.init)
            .filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return true }

        return tokens.allSatisfy { token in
            let digits = token.filter(\.isNumber)
            if digits.count == token.count {
                return !digits.isEmpty && phoneDigits.contains(digits)
            }
            return firstName.localizedStandardContains(token)
                || lastName.localizedStandardContains(token)
                || fullName.localizedStandardContains(token)
        }
    }
}
