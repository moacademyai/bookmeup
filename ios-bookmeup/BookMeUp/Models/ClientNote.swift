import Foundation

/// An internal note the team keeps about a client.
///
/// Notes belong to the client record, not to a screen, so they survive navigation
/// and are readable from anywhere the client is shown.
nonisolated struct ClientNote: Identifiable, Hashable, Codable {
    let id: UUID
    let clientID: UUID
    var text: String
    let createdAt: Date
    /// Which team member wrote it.
    let author: String

    init(
        id: UUID = UUID(),
        clientID: UUID,
        text: String,
        createdAt: Date = Date(),
        author: String
    ) {
        self.id = id
        self.clientID = clientID
        self.text = text
        self.createdAt = createdAt
        self.author = author
    }
}
