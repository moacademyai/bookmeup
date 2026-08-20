import Foundation

/// An authenticated account, as the app sees it after sign-in and verification.
///
/// Today the values come from the demo session; when real authentication lands, the
/// same struct is filled from the identity provider and nothing downstream changes.
nonisolated struct ClientAccount: Hashable {
    /// The stable subject id of the authenticated account.
    let accountID: String
    let firstName: String
    let lastName: String
    /// Verified number — the strongest signal for finding an existing salon client.
    let phone: String
    let email: String?

    var fullName: String {
        lastName.isEmpty ? firstName : "\(firstName) \(lastName)"
    }
}

/// The bridge between an authenticated account and the salon's client record.
///
/// This is what stops a person who has visited for years from becoming a second client
/// the day they install the app: the account is linked to the record that already
/// exists, so bookings, history and the Beauty Passport stay exactly where they are.
nonisolated struct ClientAccountLink: Codable, Hashable {
    let accountID: String
    let clientID: UUID
    let linkedAt: Date
    /// How the existing record was recognised — kept for support and audit questions.
    let method: ClientLinkMethod

    init(accountID: String, clientID: UUID, linkedAt: Date = Date(), method: ClientLinkMethod) {
        self.accountID = accountID
        self.clientID = clientID
        self.linkedAt = linkedAt
        self.method = method
    }
}

/// How an account was matched to a client record.
nonisolated enum ClientLinkMethod: String, Codable, Hashable {
    /// Matched on the normalised E.164 number — the reliable path.
    case verifiedPhone
    /// Matched on an exact full name, used only when no number is on file.
    case name
    /// No existing record, so a new client was created for this account.
    case created

    var title: String {
        switch self {
        case .verifiedPhone: "Pagal patvirtintą numerį"
        case .name: "Pagal vardą"
        case .created: "Sukurtas naujas įrašas"
        }
    }
}
