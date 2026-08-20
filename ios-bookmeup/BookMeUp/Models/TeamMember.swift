import Foundation

/// A specialist working on the salon floor.
///
/// The same record serves two audiences. The team calendar needs only a name and a
/// craft; the client choosing who will do their hair needs to know who this person is,
/// what they are trusted with and what they are allowed to perform. Everything beyond
/// the name is therefore optional — a business that published nothing about a colleague
/// still gets a working calendar column, and the client-facing card simply shows less.
nonisolated struct TeamMember: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let craft: String
    var isCurrentUser: Bool = false
    /// The business this person works at. `nil` keeps older calendar-only records valid.
    var providerID: UUID?
    /// Services this person performs, by name. Empty means the whole catalogue — that
    /// is what makes a one-chair business work without listing anything.
    var serviceNames: [String] = []
    var rating: Double?
    var reviewCount: Int?
    var yearsExperience: Int?
    /// One or two sentences in the specialist's own voice, shown when choosing them.
    var bio: String = ""

    var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first }.map(String.init).joined().uppercased()
    }

    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    /// Whether this person is allowed to perform a service. A specialist with no
    /// declared list can do everything the business offers.
    func canPerform(_ service: ServiceOffering) -> Bool {
        serviceNames.isEmpty || serviceNames.contains(service.name)
    }

    /// "4,9", or `nil` when this specialist has no rating of their own.
    var ratingText: String? {
        guard let rating else { return nil }
        return String(format: "%.1f", rating).replacingOccurrences(of: ".", with: ",")
    }

    /// "8 m. patirties", or `nil` when the business never said.
    var experienceText: String? {
        guard let yearsExperience, yearsExperience > 0 else { return nil }
        return "\(yearsExperience) \(LithuanianPlural.year(yearsExperience)) patirties"
    }
}
