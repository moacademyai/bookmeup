import SwiftUI

/// A BookMeUp business on the map.
///
/// A plain anonymous pin makes a client tap every marker to learn anything, so this shows
/// the rating and the name — the two things that decide whether a place is worth opening.
/// It stays small on purpose: a map covered in labels is not a map.
///
/// The marker simplifies itself as the view widens. Zoomed in there is room for the name;
/// zoomed out, or when many businesses share the view, it collapses to a rating dot so the
/// map stays readable instead of becoming a wall of text.
struct BusinessMarker: View {
    let provider: Provider
    let isSelected: Bool
    /// How much detail the current map scale can carry.
    let detail: Detail

    enum Detail {
        /// Room for the rating and the business name.
        case full
        /// Room for the rating only.
        case rating
        /// Nothing but a dot — the map is showing too wide an area for labels.
        case dot
    }

    private var foreground: Color { isSelected ? Palette.onPine : Palette.ink }
    private var background: Color { isSelected ? Palette.pine : Palette.surface }

    var body: some View {
        Group {
            switch detail {
            case .full: label(showsName: true)
            case .rating: label(showsName: false)
            case .dot: dot
            }
        }
        .shadow(color: Color(hex: 0x16241F).opacity(0.18), radius: 6, y: 2)
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: detail)
        .accessibilityLabel("\(provider.name), \(provider.ratingText) žvaigždutės")
    }

    private func label(showsName: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "star.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Palette.marigold)
            Text(provider.ratingText)
                .font(.caption2.weight(.bold).monospacedDigit())
                .foregroundStyle(foreground)
            if showsName {
                Text(provider.name)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(foreground)
                    .lineLimit(1)
                    .frame(maxWidth: 108, alignment: .leading)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(minHeight: 32)
        .background(background, in: .capsule)
        .overlay {
            Capsule().stroke(isSelected ? Palette.marigold : Palette.hairline, lineWidth: isSelected ? 1.5 : 1)
        }
    }

    private var dot: some View {
        Image(systemName: provider.category.symbolName)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(isSelected ? Palette.onPine : Palette.forest)
            .frame(width: isSelected ? 34 : 30, height: isSelected ? 34 : 30)
            .background(background, in: .circle)
            .overlay {
                Circle().stroke(isSelected ? Palette.marigold : Palette.hairline, lineWidth: isSelected ? 1.5 : 1)
            }
    }
}
