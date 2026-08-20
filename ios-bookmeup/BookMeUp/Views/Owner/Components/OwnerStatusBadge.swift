import SwiftUI

/// Small state mark: a role, a readiness, a status.
struct OwnerStatusBadge: View {
    enum Tone {
        case neutral
        case positive
        case warning
        case critical

        var tint: Color {
            switch self {
            case .neutral: Palette.inkSoft
            case .positive: Palette.forest
            case .warning: Palette.marigold
            case .critical: Palette.terracotta
            }
        }
    }

    let text: String
    var tone: Tone = .neutral
    var symbolName: String?

    var body: some View {
        HStack(spacing: 4) {
            if let symbolName {
                Image(systemName: symbolName)
                    .font(.caption2.weight(.bold))
            }
            Text(text)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(tone == .neutral ? Palette.inkSoft : tone.tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tone.tint.opacity(tone == .neutral ? 0.1 : 0.15), in: .capsule)
    }
}
