import SwiftUI

/// The input bar pinned under a conversation.
///
/// Once a conversation exists there is nothing left to teach, so this is only a field and
/// a send button — no examples, no explanation, no decoration competing with the answers
/// above it.
struct AssistantComposer: View {
    @Binding var text: String
    var placeholder: String = "Ko ieškai?"
    var onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundStyle(Palette.inkSoft.opacity(0.7))
                        .allowsHitTesting(false)
                }
                TextField("", text: $text, axis: .vertical)
                    .font(.body)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1...4)
                    .focused($isFocused)
                    .tint(Palette.forest)
                    .submitLabel(.search)
                    .onSubmit(submit)
            }
            .frame(minHeight: 24, alignment: .topLeading)

            Button(action: submit) {
                Image(systemName: "arrow.up")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(canSend ? Color(hex: 0x16241F) : Palette.inkSoft)
                    .frame(width: 38, height: 38)
                    .background(
                        canSend ? Palette.marigold : Palette.eucalyptus.opacity(0.5),
                        in: .circle
                    )
            }
            .buttonStyle(ExperienceCardPressStyle())
            .disabled(!canSend)
            .accessibilityLabel("Siųsti")
        }
        .padding(12)
        .background(Palette.surface, in: .rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(isFocused ? Palette.forest.opacity(0.45) : Palette.hairline, lineWidth: 1)
        }
        .contentShape(.rect(cornerRadius: 22))
        .onTapGesture { isFocused = true }
        .animation(.easeOut(duration: 0.2), value: isFocused)
    }

    private func submit() {
        guard canSend else { return }
        isFocused = false
        onSubmit()
    }
}
