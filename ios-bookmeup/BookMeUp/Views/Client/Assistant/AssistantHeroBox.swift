import SwiftUI

/// The assistant box — the one thing the first screen asks a client to use.
///
/// It is deliberately large and mostly empty. The examples drifting through it are not
/// content, they are an explanation: they show what can be said here and then get out of
/// the way. The moment the client starts typing they disappear entirely, because at that
/// point the client no longer needs to be taught anything.
struct AssistantHeroBox: View {
    @Binding var text: String
    /// Examples to drift through the box. Empty disables the animation.
    var prompts: [String] = []
    /// Focus is owned by the screen, not by this box, so tapping anywhere outside can
    /// give the keyboard back.
    @FocusState.Binding var isFocused: Bool
    var onSubmit: () -> Void

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The examples step aside as soon as the client has something of their own to say.
    private var showsPrompts: Bool {
        !prompts.isEmpty && text.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if showsPrompts {
                AssistantPromptCloud(prompts: prompts) { prompt in
                    text = prompt
                    isFocused = true
                }
                .transition(.opacity)
            }

            inputRow
        }
        .padding(20)
        .background(Palette.surface, in: .rect(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(isFocused ? Palette.forest.opacity(0.45) : Palette.hairline, lineWidth: isFocused ? 1.5 : 1)
        }
        .shadow(color: Palette.ink.opacity(0.05), radius: 22, y: 10)
        .contentShape(.rect(cornerRadius: 28))
        .onTapGesture { isFocused = true }
        .animation(.easeInOut(duration: 0.3), value: showsPrompts)
        .animation(.easeOut(duration: 0.2), value: isFocused)
    }

    private var inputRow: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Pasakyk savais žodžiais")
                        .font(.body)
                        .foregroundStyle(Palette.inkSoft.opacity(0.7))
                        .allowsHitTesting(false)
                }
                TextField("", text: $text, axis: .vertical)
                    .font(.body)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1...5)
                    .focused($isFocused)
                    .tint(Palette.forest)
                    .submitLabel(.search)
                    .onSubmit(submit)
            }
            .frame(minHeight: 26, alignment: .topLeading)

            sendButton
        }
    }

    private var sendButton: some View {
        Button(action: submit) {
            Image(systemName: "arrow.up")
                .font(.headline.weight(.bold))
                .foregroundStyle(canSend ? Color(hex: 0x16241F) : Palette.inkSoft)
                .frame(width: 48, height: 48)
                .background(
                    canSend ? Palette.marigold : Palette.eucalyptus.opacity(0.5),
                    in: .circle
                )
        }
        .buttonStyle(ExperienceCardPressStyle())
        .disabled(!canSend)
        .sensoryFeedback(.impact(weight: .light), trigger: canSend)
        .accessibilityLabel("Siųsti")
    }

    private func submit() {
        guard canSend else { return }
        isFocused = false
        onSubmit()
    }
}
