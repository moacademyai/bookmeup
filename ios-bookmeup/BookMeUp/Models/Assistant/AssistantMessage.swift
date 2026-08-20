import Foundation

/// Where the results in a reply came from.
///
/// Shown in the conversation so nobody mistakes the current local matching for a live
/// marketplace. When a backend is connected it reports `.live` and the notice disappears.
nonisolated enum AssistantDataSource: String, Hashable {
    /// Matched on this device against the demo catalogue bundled with the app.
    case demoCatalogue
    /// Returned by the BookMeUp booking service.
    case live

    var notice: String? {
        switch self {
        case .demoCatalogue: "Rezultatai iš demonstracinio katalogo šiame įrenginyje."
        case .live: nil
        }
    }
}

/// What the assistant produced for one request.
nonisolated struct AssistantReply: Hashable {
    /// The assistant's sentence above the results.
    let text: String
    let query: AssistantQuery
    let offers: [AssistantOffer]
    /// Follow-ups worth showing for this particular result set.
    let refinements: [AssistantRefinement]
    let source: AssistantDataSource
}

/// One turn in the conversation.
nonisolated struct AssistantMessage: Identifiable, Hashable {
    enum Author: Hashable {
        case client
        case assistant
    }

    let id: UUID
    let author: Author
    let text: String
    let sentAt: Date
    /// Present only on assistant turns that produced bookable options.
    let reply: AssistantReply?

    init(
        id: UUID = UUID(),
        author: Author,
        text: String,
        sentAt: Date = Date(),
        reply: AssistantReply? = nil
    ) {
        self.id = id
        self.author = author
        self.text = text
        self.sentAt = sentAt
        self.reply = reply
    }

    static func client(_ text: String) -> AssistantMessage {
        AssistantMessage(author: .client, text: text)
    }

    static func assistant(_ reply: AssistantReply) -> AssistantMessage {
        AssistantMessage(author: .assistant, text: reply.text, reply: reply)
    }

    static func assistant(text: String) -> AssistantMessage {
        AssistantMessage(author: .assistant, text: text)
    }
}
