import SwiftUI

/// One bookable option inside the conversation.
///
/// This is what separates a booking assistant from a chatbot: the answer is not a
/// paragraph describing a salon, it is the place, the service, the price and real times
/// with one action that books them. The times shown are the ones the booking sheet would
/// offer — tapping through never discovers that the slot was never free.
struct AssistantOfferCardView: View {
    let offer: AssistantOffer
    var isPrimary: Bool = false
    var onOpenProvider: () -> Void
    var onBook: (Date) -> Void

    @State private var selectedSlot: Date?

    private var activeSlot: Date? { selectedSlot ?? offer.recommendedSlot }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            slotRow
            if let activeSlot {
                Button {
                    onBook(activeSlot)
                } label: {
                    Text("Rezervuoti \(activeSlot.timeText)")
                }
                .buttonStyle(MarigoldButtonStyle())
                .sensoryFeedback(.selection, trigger: activeSlot)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Palette.surface, in: .rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(isPrimary ? Palette.forest.opacity(0.35) : Palette.hairline, lineWidth: isPrimary ? 1.5 : 1)
        }
    }

    private var header: some View {
        Button(action: onOpenProvider) {
            HStack(alignment: .top, spacing: 12) {
                AssetImage(name: offer.provider.imageName, height: 72, width: 72, cornerRadius: 16)

                VStack(alignment: .leading, spacing: 5) {
                    if let reason = offer.reason {
                        Text(reason)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Palette.forest)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Palette.eucalyptus.opacity(0.5), in: .capsule)
                    }

                    Text(offer.provider.name)
                        .font(.headline)
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    Label(offer.provider.reviewLine, systemImage: "star.fill")
                        .font(.caption.weight(.medium).monospacedDigit())
                        .foregroundStyle(Palette.marigold.mix(with: Palette.ink, amount: 0.25))

                    HStack(spacing: 8) {
                        Text(offer.distanceText ?? offer.provider.district)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Palette.inkSoft)
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(Palette.inkSoft)
                        Text("\(offer.service.name) · \(offer.service.priceText)")
                            .font(.caption.weight(.medium).monospacedDigit())
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .buttonStyle(ExperienceCardPressStyle())
    }

    private var slotRow: some View {
        HStack(spacing: 8) {
            ForEach(offer.slots, id: \.timeIntervalSince1970) { slot in
                let isSelected = activeSlot == slot
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        selectedSlot = slot
                    }
                } label: {
                    Text(slot.timeText)
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(isSelected ? Palette.bone : Palette.ink)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(isSelected ? Palette.forest : Palette.bone, in: .rect(cornerRadius: 13))
                        .overlay {
                            RoundedRectangle(cornerRadius: 13)
                                .stroke(isSelected ? Color.clear : Palette.hairline, lineWidth: 1)
                        }
                }
                .buttonStyle(ExperienceCardPressStyle())
            }
        }
    }
}
