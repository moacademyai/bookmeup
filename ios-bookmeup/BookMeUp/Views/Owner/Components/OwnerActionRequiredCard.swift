import SwiftUI

/// Something that needs an owner decision.
///
/// Severity is carried by a single accent stripe rather than a loud colour block —
/// the list has to stay readable when the day goes wrong.
struct OwnerActionRequiredCard: View {
    let item: ActionRequiredItem

    private var tint: Color {
        switch item.severity {
        case .critical: Palette.terracotta
        case .attention: Palette.marigold
        case .info: Palette.forest
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(tint)
                .frame(width: 3)

            Image(systemName: item.symbolName)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.15), in: .circle)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.leading)
                Text(item.detail)
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.inkSoft.opacity(0.6))
        }
        .padding(.vertical, 12)
        .padding(.trailing, 14)
        .padding(.leading, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Palette.hairline, lineWidth: 1)
        }
        .contentShape(Rectangle())
    }
}
