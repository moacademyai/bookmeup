import Foundation

/// A person in the salon's client base.
///
/// This is the single client record for the whole product: the specialist's client
/// list, calendar booking, appointment details and — later — the client environment
/// all read the same object. `fullName` is the key that links a client to their
/// bookings, so it must always match `Booking.clientName`.
nonisolated struct Client: Identifiable, Hashable, Codable {
    let id: UUID
    var firstName: String
    var lastName: String
    var phone: String
    /// Optional — the base only requires a name and a number.
    var email: String?
    /// When the client entered the base — used for tenure and visit-rate math.
    var createdAt: Date

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String = "",
        phone: String = "",
        email: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.email = email
        self.createdAt = createdAt
    }

    /// Builds a client from a single display name, e.g. one typed into the calendar.
    static func named(_ fullName: String, phone: String = "", createdAt: Date = Date()) -> Client {
        let parts = fullName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ", maxSplits: 1)
            .map(String.init)
        return Client(
            firstName: parts.first ?? fullName,
            lastName: parts.count > 1 ? parts[1] : "",
            phone: phone,
            createdAt: createdAt
        )
    }

    var fullName: String {
        lastName.isEmpty ? firstName : "\(firstName) \(lastName)"
    }

    var initials: String {
        [firstName, lastName]
            .compactMap { $0.first }
            .prefix(2)
            .map(String.init)
            .joined()
            .uppercased()
    }

    /// Digits only, so a search for "948" also matches "+370 686 22 948".
    var phoneDigits: String { phone.filter(\.isNumber) }

    var hasPhone: Bool { !phone.trimmingCharacters(in: .whitespaces).isEmpty }

    var hasEmail: Bool { !(email ?? "").trimmingCharacters(in: .whitespaces).isEmpty }

    /// Tappable number for the Call action.
    var callURL: URL? {
        guard hasPhone else { return nil }
        return URL(string: "tel://\(phone.filter { $0.isNumber || $0 == "+" })")
    }
}
