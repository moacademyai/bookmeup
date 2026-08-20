import SwiftUI

/// One visit in the client's history: when, what, by whom, for how much.
struct ClientVisitRow: View {
    let booking: Booking

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(booking.start.shortDayMonthText) · \(booking.start.timeText)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Palette.ink)
                Text(booking.serviceName)
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text(booking.specialistName)
                    .font(.caption2)
                    .foregroundStyle(Palette.inkSoft.opacity(0.85))
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text(booking.price.asEuro)
                    .font(.subheadline.weight(.medium).monospacedDigit())
                    .foregroundStyle(Palette.ink)
                // Only ever shown when the visit did not simply happen as planned.
                if booking.status == .cancelled {
                    Text(booking.status.title)
                        .font(.caption2)
                        .foregroundStyle(Palette.terracotta)
                }
            }
        }
        .padding(.vertical, 12)
    }
}

/// The client's full visit history, opened from the profile.
///
/// Loaded when it is asked for rather than with the profile, so opening a client with
/// years of history stays as fast as opening a new one.
struct ClientHistorySheet: View {
    let clientName: String
    let visits: [Booking]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if visits.isEmpty {
                        Text("Vizitų dar nebuvo.")
                            .font(.subheadline)
                            .foregroundStyle(Palette.inkSoft)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 28)
                    } else {
                        ForEach(Array(visits.enumerated()), id: \.element.id) { index, booking in
                            ClientVisitRow(booking: booking)
                            if index < visits.count - 1 {
                                Divider().overlay(Palette.hairline)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .background(Palette.bone)
            .scrollIndicators(.hidden)
            .navigationTitle("Vizitų istorija")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Uždaryti") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationContentInteraction(.scrolls)
    }
}
