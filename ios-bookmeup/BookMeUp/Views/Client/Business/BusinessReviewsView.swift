import SwiftUI

/// One review, as it appears on a profile.
struct ReviewRow: View {
    let review: ProviderReview

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                InitialsAvatar(name: review.authorName, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.ink)
                    Text(review.date.dayText)
                        .font(.caption2)
                        .foregroundStyle(Palette.inkSoft)
                }
                Spacer(minLength: 4)
                StarRatingView(rating: Double(review.rating), size: 11)
            }

            if !review.text.isEmpty {
                Text(review.text)
                    .font(.footnote)
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A row of stars. Used wherever a rating is shown as more than a number.
struct StarRatingView: View {
    let rating: Double
    var size: CGFloat = 13

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: Double(star) <= rating.rounded() ? "star.fill" : "star")
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(Double(star) <= rating.rounded() ? Palette.marigold : Palette.hairline)
            }
        }
        .accessibilityLabel("\(String(format: "%.1f", rating)) iš 5")
    }
}

/// The full review list of one business.
struct BusinessReviewsView: View {
    let provider: Provider

    @Environment(BookMeUpStore.self) private var store

    private var reviews: [ProviderReview] {
        store.reviews(for: provider.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summary

                if reviews.isEmpty {
                    Text("Šis verslas dar neturi atsiliepimų.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.inkSoft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardSurface()
                } else {
                    VStack(spacing: 0) {
                        ForEach(reviews) { review in
                            ReviewRow(review: review)
                                .padding(.vertical, 14)
                            if review.id != reviews.last?.id {
                                Divider().overlay(Palette.hairline)
                            }
                        }
                    }
                    .cardSurface(padding: 16)
                }

                if reviews.contains(where: { $0.source == .demoCatalogue }) {
                    Label(
                        "Dalis atsiliepimų yra iš demonstracinio katalogo.",
                        systemImage: "info.circle"
                    )
                    .font(.caption2)
                    .foregroundStyle(Palette.inkSoft)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle("Atsiliepimai")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(Palette.bone, for: .navigationBar)
    }

    private var summary: some View {
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text(provider.ratingText)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                StarRatingView(rating: provider.rating)
            }
            VStack(alignment: .leading, spacing: 4) {
                if let count = provider.reviewCountText {
                    Text(count)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.ink)
                }
                Text("\(provider.visitCount) apsilankymai per BookMeUp")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .cardSurface(padding: 16)
    }
}
