import Foundation

/// Where a review came from.
///
/// The distinction is the whole point: a review a client wrote in this app is real
/// BookMeUp data, while seeded demo reviews exist so the profile has something to show
/// before the platform has traffic. The UI says which is which instead of presenting
/// both as production content.
nonisolated enum ReviewSource: String, Codable, Hashable {
    /// Written by a client of this app, after a visit that actually happened.
    case client
    /// Seed content for the development catalogue.
    case demoCatalogue

    var notice: String? {
        switch self {
        case .client: nil
        case .demoCatalogue: "Demonstracinio katalogo atsiliepimas"
        }
    }
}

/// One review of a business, always attached to the visit it is about.
///
/// `bookingID` is what keeps reviews honest: a client can only review a visit they
/// actually had, and only once.
nonisolated struct ProviderReview: Identifiable, Codable, Hashable {
    let id: UUID
    let providerID: UUID
    /// The visit being reviewed. `nil` only for seeded demo content.
    let bookingID: UUID?
    let clientID: UUID?
    let authorName: String
    /// 1–5.
    let rating: Int
    let text: String
    let date: Date
    let source: ReviewSource

    init(
        id: UUID = UUID(),
        providerID: UUID,
        bookingID: UUID? = nil,
        clientID: UUID? = nil,
        authorName: String,
        rating: Int,
        text: String = "",
        date: Date = Date(),
        source: ReviewSource = .client
    ) {
        self.id = id
        self.providerID = providerID
        self.bookingID = bookingID
        self.clientID = clientID
        self.authorName = authorName
        self.rating = min(max(rating, 1), 5)
        self.text = text
        self.date = date
        self.source = source
    }

    /// "Ieva K." — reviews are public, full surnames are not.
    var displayName: String {
        let parts = authorName.split(separator: " ")
        guard let first = parts.first else { return authorName }
        guard let last = parts.dropFirst().first, let initial = last.first else { return String(first) }
        return "\(first) \(initial)."
    }
}
