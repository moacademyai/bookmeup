import SwiftUI

/// A navigation row in the profile hub.
///
/// The hub's whole job is to point somewhere, so a row says what lives behind it and,
/// at most, one line of what is currently true there. Anything more belongs on the screen
/// it leads to.
struct ProfileRow<Destination: View>: View {
    let title: String
    var value: String?
    let symbolName: String
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: symbolName)
                    .font(.footnote)
                    .foregroundStyle(Palette.forest)
                    .frame(width: 34, height: 34)
                    .background(Palette.eucalyptus.opacity(0.4), in: .rect(cornerRadius: 10))

                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Palette.ink)

                Spacer(minLength: 8)

                if let value {
                    Text(value)
                        .font(.caption)
                        .foregroundStyle(Palette.inkSoft)
                        .lineLimit(1)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.inkSoft)
            }
            .frame(minHeight: 44)
            .padding(.vertical, 6)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

/// A group of profile rows on one card.
struct ProfileRowGroup<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .cardSurface(padding: 16)
    }
}

/// The hairline used between profile rows.
struct ProfileRowDivider: View {
    var body: some View {
        Divider().overlay(Palette.hairline)
    }
}
