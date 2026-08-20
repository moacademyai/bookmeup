import SwiftUI

/// The compact card that appears when a business is tapped on the map.
///
/// It answers the three questions a marker cannot — is it good, how far is it, when can I
/// go — and then gets out of the way. It stays deliberately short: the map is the screen,
/// and a preview that covers half of it stops being a preview.
struct BusinessPreviewCard: View {
    let provider: Provider
    var distanceMetres: Double?
    var isFavorite: Bool
    var onOpen: () -> Void
    var onBook: () -> Void
    var onToggleFavorite: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onOpen) {
                HStack(alignment: .top, spacing: 12) {
                    AssetImage(name: provider.imageName, height: 58, width: 58, cornerRadius: 14)

                    VStack(alignment: .leading, spacing: 3) {
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
                            if let count = provider.reviewCountText {
                                Text("· \(count)")
                                    .font(.caption)
                                    .foregroundStyle(Palette.inkSoft)
                                    .lineLimit(1)
                            }
                        }

                        Text(subtitle)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Palette.inkSoft)
                            .lineLimit(1)

                        Text("Artimiausias laikas \(provider.nextSlot.timeText)")
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Palette.forest)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(.rect)
            }
            .buttonStyle(ExperienceCardPressStyle())

            HStack(spacing: 10) {
                Button(action: onBook) {
                    Text("Registruotis")
                }
                .buttonStyle(MarigoldButtonStyle())

                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isFavorite ? Palette.terracotta : Palette.inkSoft)
                        .frame(width: 52, height: 52)
                        .background(Palette.bone, in: .rect(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16).stroke(Palette.hairline, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: isFavorite)
                .accessibilityLabel(isFavorite ? "Pašalinti iš mėgstamiausių" : "Įtraukti į mėgstamiausius")
            }
        }
        .padding(14)
        .background(Palette.elevated, in: .rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24).stroke(Palette.hairline, lineWidth: 1)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Palette.inkSoft)
                    .frame(width: 30, height: 30)
                    .background(Palette.bone, in: .circle)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .padding(8)
            .accessibilityLabel("Uždaryti")
        }
        .shadow(color: Color(hex: 0x16241F).opacity(0.16), radius: 20, y: 8)
    }

    /// Distance when the client's position is known, the neighbourhood when it is not.
    private var subtitle: String {
        let place = distanceMetres.map(DistanceText.short) ?? provider.district
        return "\(place) · \(provider.priceLevelText)"
    }
}
