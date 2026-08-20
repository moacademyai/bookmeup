import SwiftUI

/// What a screen says when it has nothing true to show.
///
/// The owner environment never fills a card with invented figures to look finished.
/// If a number has no source yet, this states plainly what will produce it.
struct OwnerEmptyState: View {
    let title: String
    let message: String
    var symbolName: String = "tray"
    /// Optional list of what will live here once the mechanism runs.
    var bullets: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: symbolName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.forest)
                    .frame(width: 34, height: 34)
                    .background(Palette.eucalyptus.opacity(0.35), in: .circle)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Spacer(minLength: 0)
            }

            Text(message)
                .font(.footnote)
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            if !bullets.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Palette.eucalyptus)
                                .frame(width: 5, height: 5)
                                .padding(.top, 6)
                            Text(bullet)
                                .font(.footnote)
                                .foregroundStyle(Palette.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 16)
    }
}
