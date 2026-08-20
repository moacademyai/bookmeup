import SwiftUI

/// One business in a list.
///
/// Used by Sąrašas and by Mėgstamiausi, because a business looks the same wherever it is
/// listed — only the reason it is there changes. Kept to one compact row: a list where
/// every card is a poster is a list nobody scrolls.
struct BusinessRowCard: View {
    let provider: Provider
    var distanceMetres: Double?
    /// Replaces the availability line when the row is about something else, such as a
    /// past visit.
    var footnote: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AssetImage(name: provider.imageName, height: 72, width: 72, cornerRadius: 16)

                VStack(alignment: .leading, spacing: 4) {
                    Text(provider.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Palette.marigold)
                        Text(provider.ratingText)
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Palette.ink)
                        if let reviewCount = provider.reviewCount {
                            Text("· \(reviewCount)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Palette.inkSoft)
                        }
                    }

                    Text(placeLine)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Palette.inkSoft)
                        .lineLimit(1)

                    Text(footnote ?? "Artimiausias laikas \(provider.nextSlot.timeText)")
                        .font(.caption.weight(.medium).monospacedDigit())
                        .foregroundStyle(Palette.forest)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(padding: 12, cornerRadius: 20)
        }
        .buttonStyle(ExperienceCardPressStyle())
    }

    /// Distance when the client's position is known, the neighbourhood when it is not.
    private var placeLine: String {
        let place = distanceMetres.map(DistanceText.short) ?? provider.district
        return "\(place) · \(provider.priceLevelText)"
    }
}
