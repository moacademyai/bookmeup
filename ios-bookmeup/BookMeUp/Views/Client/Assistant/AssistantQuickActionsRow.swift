import SwiftUI

/// A shortcut that sends a ready-made request to the assistant.
///
/// Quick actions are not a second navigation system — each one is literally a sentence
/// the client could have typed, which is why they run through the same parser and produce
/// the same kind of answer.
nonisolated struct AssistantQuickAction: Identifiable, Hashable {
    let id: String
    let title: String
    let symbolName: String
    /// The request this chip sends on the client's behalf.
    let request: String

    static let freeToday = AssistantQuickAction(
        id: "free-today",
        title: "Laisva šiandien",
        symbolName: "clock",
        request: "Kas laisva šiandien?"
    )

    static let nearby = AssistantQuickAction(
        id: "nearby",
        title: "Netoli manęs",
        symbolName: "location",
        request: "Kas yra netoli manęs?"
    )

    static let repeatVisit = AssistantQuickAction(
        id: "repeat",
        title: "Pakartoti vizitą",
        symbolName: "arrow.trianglehead.clockwise",
        request: "Noriu vėl ten, kur paskutinį kartą lankiausi."
    )

    /// The three shortcuts under the assistant box. Fixed, so the screen never changes
    /// shape between clients.
    static let clientDefaults: [AssistantQuickAction] = [.freeToday, .nearby, .repeatVisit]
}

/// The three compact actions under the assistant box.
///
/// For clients who would rather not type. Kept visually quiet and equally sized so the
/// row reads as one control rather than three competing calls to action — and so it
/// always fits the width of a phone instead of scrolling off the edge.
struct AssistantQuickActionsRow: View {
    var actions: [AssistantQuickAction] = AssistantQuickAction.clientDefaults
    var onSelect: (AssistantQuickAction) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(actions) { action in
                Button {
                    onSelect(action)
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: action.symbolName)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Palette.forest)
                        Text(action.title)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: .infinity, minHeight: 62)
                    .background(Palette.surface, in: .rect(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18).stroke(Palette.hairline, lineWidth: 1)
                    }
                }
                .buttonStyle(ExperienceCardPressStyle())
                .accessibilityLabel(action.title)
            }
        }
    }
}
