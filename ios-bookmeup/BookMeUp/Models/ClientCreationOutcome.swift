import Foundation

/// Result of trying to add a client by hand.
///
/// The base is keyed by phone number, so an attempt to add someone who is already
/// there returns the existing record instead of creating a second one.
nonisolated enum ClientCreationOutcome {
    case created(Client)
    case duplicate(Client)
    /// The number could not be read as a real phone number — nothing was written.
    case invalidPhone

    var client: Client? {
        switch self {
        case .created(let client), .duplicate(let client): client
        case .invalidPhone: nil
        }
    }
}
