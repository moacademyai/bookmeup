import SwiftUI

/// A titled block of owner content with an optional short explanation.
///
/// Used everywhere so the owner environment reads as one product and a new module
/// never invents its own section styling.
struct OwnerSection<Content: View>: View {
    let title: String
    var caption: String?
    var accessory: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                SectionHeader(title: title, accessory: accessory)
                if let caption {
                    Text(caption)
                        .font(.footnote)
                        .foregroundStyle(Palette.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            content
        }
    }
}

/// A card that stacks rows with hairline dividers between them.
struct SettingsGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Palette.surface, in: .rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Palette.hairline, lineWidth: 1)
        }
    }
}

/// Divider matching the card language, for use between rows of a `SettingsGroup`.
struct SettingsDivider: View {
    var body: some View {
        Divider()
            .overlay(Palette.hairline)
            .padding(.leading, 62)
    }
}
