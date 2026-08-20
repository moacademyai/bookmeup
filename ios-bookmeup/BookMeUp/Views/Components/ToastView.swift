import SwiftUI

/// Lightweight confirmation toast used after booking actions.
struct ToastView: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Palette.onPine)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Palette.pine, in: .capsule)
            .shadow(color: Palette.ink.opacity(0.18), radius: 12, y: 4)
            .padding(.horizontal, 20)
    }
}
