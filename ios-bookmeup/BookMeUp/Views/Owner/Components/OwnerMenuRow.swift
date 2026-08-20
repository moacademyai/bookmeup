import SwiftUI

/// One navigable line of the owner environment.
///
/// Progressive disclosure lives here: a layer shows categories as rows, and the
/// detail only opens when the owner asks for it. The whole row is the tap target.
struct OwnerMenuRow: View {
    let title: String
    var subtitle: String?
    let symbolName: String
    var tint: Color = Palette.forest
    var badge: String?
    var badgeTone: OwnerStatusBadge.Tone = .neutral
    var trailingText: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.14), in: .rect(cornerRadius: 11))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.leading)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Palette.inkSoft)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            if let trailingText {
                Text(trailingText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Palette.inkSoft)
            }
            if let badge {
                OwnerStatusBadge(text: badge, tone: badgeTone)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.inkSoft.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}

/// A menu row that pushes an owner route. Keeps every list consistent and makes the
/// whole row — not just the label — a 56pt tap target.
struct OwnerModuleRow: View {
    let module: OwnerModule

    var body: some View {
        NavigationLink(value: OwnerRoute.module(module)) {
            OwnerMenuRow(
                title: module.title,
                subtitle: module.subtitle,
                symbolName: module.symbolName,
                badge: module.readiness == .foundation ? module.readiness.title : nil,
                badgeTone: .neutral
            )
        }
        .buttonStyle(.plain)
    }
}
