import SwiftUI

/// Elevated bone/ivory surface with a thin eucalyptus hairline — the app's core card.
struct CardSurface: ViewModifier {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Palette.surface, in: .rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Palette.hairline, lineWidth: 1)
            }
    }
}

extension View {
    func cardSurface(padding: CGFloat = 16, cornerRadius: CGFloat = 22) -> some View {
        modifier(CardSurface(padding: padding, cornerRadius: cornerRadius))
    }
}

/// Section title with the quiet editorial rhythm used across the app.
struct SectionHeader: View {
    let title: String
    var accessory: String?
    var onDark: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(onDark ? Palette.bone : Palette.ink)
            Spacer(minLength: 8)
            if let accessory {
                Text(accessory)
                    .font(.subheadline)
                    .foregroundStyle(onDark ? Palette.eucalyptus.opacity(0.8) : Palette.inkSoft)
            }
        }
    }
}
