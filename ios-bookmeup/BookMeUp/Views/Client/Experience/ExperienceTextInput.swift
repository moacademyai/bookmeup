import SwiftUI

/// The free-text answer.
///
/// The whole visible card is the tap target — a client should never have to find the
/// one line of text inside it. The card owns the focus state and passes taps to the
/// field, which is why the empty space below the text still opens the keyboard.
struct ExperienceTextInput: View {
    let placeholder: String
    @Binding var text: String

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField(placeholder, text: $text, axis: .vertical)
                .font(.body)
                .foregroundStyle(Palette.ink)
                .lineLimit(4...10)
                .focused($isFocused)
                .submitLabel(.return)

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background(Palette.surface, in: .rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(isFocused ? Palette.forest : Palette.hairline, lineWidth: isFocused ? 1.5 : 1)
        }
        .contentShape(.rect(cornerRadius: 20))
        .onTapGesture { isFocused = true }
        .animation(.easeOut(duration: 0.18), value: isFocused)
        .toolbar {
            if isFocused {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Gerai") { isFocused = false }
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
    }
}
