import Foundation
import Observation

/// The state of the client's conversation with the assistant.
///
/// Held above the tab bar so a conversation survives a trip to the map and back. It owns
/// no matching logic of its own — it hands requests to an `AssistantService` and keeps
/// the transcript, which is what will let the service be swapped for the real backend
/// without touching a single view.
@Observable
final class AssistantConversation {
    private(set) var messages: [AssistantMessage] = []
    private(set) var isThinking = false
    /// The query behind the newest reply, so a refinement knows what it is refining.
    private(set) var lastQuery: AssistantQuery?

    private let service: AssistantService

    init(service: AssistantService = LocalAssistantService()) {
        self.service = service
    }

    var isEmpty: Bool { messages.isEmpty }

    var latestReply: AssistantReply? {
        messages.last { $0.reply != nil }?.reply
    }

    /// Sends what the client typed.
    func send(_ text: String, context: AssistantContext) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let query = AssistantQueryParser.parse(trimmed)
        await run(query, clientText: trimmed, context: context)
    }

    /// Applies a follow-up to the last request instead of starting a new one.
    func refine(_ refinement: AssistantRefinement, context: AssistantContext) async {
        guard let lastQuery else { return }
        let cheapest = latestReply?.offers.map(\.service.price).min()
        let refined = refinement.applied(to: lastQuery, cheapestShown: cheapest)
        await run(refined, clientText: refinement.title, context: context)
    }

    func reset() {
        messages.removeAll()
        lastQuery = nil
        isThinking = false
    }

    private func run(_ query: AssistantQuery, clientText: String, context: AssistantContext) async {
        messages.append(.client(clientText))
        lastQuery = query
        isThinking = true

        let reply = await service.reply(to: query, context: context)

        isThinking = false
        messages.append(.assistant(reply))
    }
}
