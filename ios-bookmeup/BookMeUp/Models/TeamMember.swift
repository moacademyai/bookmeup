import Foundation

/// A specialist working on the salon floor. Used by the team calendar columns.
nonisolated struct TeamMember: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let craft: String
    var isCurrentUser: Bool = false

    var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first }.map(String.init).joined().uppercased()
    }

    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }
}
