import SwiftUI

/// Small status mark, readable on both the bone and pine surfaces.
struct StatusChip: View {
    let status: BookingStatus
    var compact: Bool = false
    var onDark: Bool = false

    var body: some View {
        Label {
            Text(status.title)
                .font(compact ? .caption2.weight(.semibold) : .subheadline.weight(.semibold))
        } icon: {
            Image(systemName: status.symbolName)
                .font(compact ? .caption2 : .subheadline)
        }
        .labelStyle(.titleAndIcon)
        .foregroundStyle(foreground)
        .padding(.horizontal, compact ? 8 : 12)
        .padding(.vertical, compact ? 4 : 7)
        .background(background, in: .capsule)
        .accessibilityLabel(status.title)
    }

    private var foreground: Color {
        if onDark {
            return status == .confirmed ? Palette.eucalyptus : status.tint
        }
        return status == .confirmed ? Palette.forest : status.tint.mix(with: Palette.ink, amount: 0.25)
    }

    private var background: Color {
        onDark ? status.tint.opacity(0.18) : status.tint.opacity(0.14)
    }
}

nonisolated extension Color {
    /// Blends two colors; used for readable status text on light surfaces.
    func mix(with other: Color, amount: Double) -> Color {
        let clamped = min(max(amount, 0), 1)
        return clamped < 0.5 ? self.opacity(1 - clamped * 0.4) : other.opacity(0.85)
    }
}
