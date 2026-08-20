import SwiftUI

/// Leaving a review for a visit that actually happened.
///
/// Short on purpose: a rating is the part everyone gives, and the words are optional. The
/// visit is named at the top so nobody reviews the wrong appointment.
struct LeaveReviewSheet: View {
    let booking: Booking
    var onSubmitted: (ProviderReview) -> Void = { _ in }

    @Environment(BookMeUpStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var rating = 5
    @State private var text = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    visitSummary
                    ratingPicker
                    comment
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .background(Palette.bone)
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Atsiliepimas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Uždaryti") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    submit()
                } label: {
                    Text("Paskelbti atsiliepimą")
                }
                .buttonStyle(MarigoldButtonStyle())
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .background(.bar)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationContentInteraction(.scrolls)
    }

    private var visitSummary: some View {
        HStack(spacing: 12) {
            AssetImage(name: booking.imageName, height: 56, width: 56, cornerRadius: 14)
            VStack(alignment: .leading, spacing: 3) {
                Text(booking.providerName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Text("\(booking.serviceName) · \(booking.start.dayText)")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 14)
    }

    private var ratingPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Kaip praėjo vizitas?")
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            rating = star
                        }
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundStyle(star <= rating ? Palette.marigold : Palette.hairline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(star) iš 5")
                }
            }
            .cardSurface(padding: 8)
            .sensoryFeedback(.selection, trigger: rating)
        }
    }

    private var comment: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Norite pridėti žodį kitą?")
            TextField("Neprivaloma", text: $text, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(Palette.ink)
                .tint(Palette.forest)
                .lineLimit(3...8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardSurface()
        }
    }

    private func submit() {
        guard let review = store.addReview(for: booking, rating: rating, text: text) else {
            dismiss()
            return
        }
        onSubmitted(review)
        dismiss()
    }
}
