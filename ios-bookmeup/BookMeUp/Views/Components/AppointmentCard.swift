import SwiftUI

/// One of the client's own visits.
///
/// The same card serves every appointment list — only the actions change, and they change
/// for a reason. A visit that has not happened yet can be moved or called off; it can
/// never be "booked again", because offering that is how a client ends up with two
/// appointments they did not mean to make.
struct AppointmentCard: View {
    let booking: Booking
    var style: Style = .upcoming
    var onOpen: () -> Void
    var onReschedule: (() -> Void)?
    var onCancel: (() -> Void)?
    var onRebook: (() -> Void)?
    var onReview: (() -> Void)?

    enum Style {
        /// A visit still ahead: change the time or cancel it.
        case upcoming
        /// A visit that happened: book the same thing again, or review it.
        case past
        /// A cancelled visit: a record, and a way to start a new booking.
        case cancelled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onOpen) {
                HStack(alignment: .top, spacing: 12) {
                    AssetImage(name: booking.imageName, height: 74, width: 74, cornerRadius: 16)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(booking.start.relativeDayTimeText)
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(style == .cancelled ? Palette.inkSoft : Palette.ink)

                        Text(booking.providerName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)

                        Text("\(booking.serviceName) · \(booking.specialistName)")
                            .font(.caption)
                            .foregroundStyle(Palette.inkSoft)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if style != .upcoming {
                            Text(booking.price.asEuro)
                                .font(.caption.weight(.medium).monospacedDigit())
                                .foregroundStyle(Palette.inkSoft)
                        }
                    }

                    Spacer(minLength: 4)

                    StatusChip(status: booking.status, compact: true)
                }
            }
            .buttonStyle(ExperienceCardPressStyle())

            actions
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 14, cornerRadius: 22)
        .opacity(style == .cancelled ? 0.82 : 1)
    }

    @ViewBuilder
    private var actions: some View {
        switch style {
        case .upcoming:
            // Deliberately no repeat booking here.
            HStack(spacing: 10) {
                if let onReschedule {
                    Button(action: onReschedule) {
                        Label("Pakeisti laiką", systemImage: "calendar")
                    }
                    .buttonStyle(QuietButtonStyle())
                }
                if let onCancel {
                    Button(action: onCancel) {
                        Label("Atšaukti", systemImage: "xmark")
                    }
                    .buttonStyle(QuietButtonStyle(tint: Palette.terracotta))
                }
            }
        case .past:
            HStack(spacing: 10) {
                if let onRebook {
                    Button(action: onRebook) {
                        Label("Rezervuoti dar kartą", systemImage: "arrow.trianglehead.clockwise")
                    }
                    .buttonStyle(QuietButtonStyle(tint: Palette.forest))
                }
                if let onReview {
                    Button(action: onReview) {
                        Label("Palikti atsiliepimą", systemImage: "star")
                    }
                    .buttonStyle(QuietButtonStyle())
                }
            }
        case .cancelled:
            if let onRebook {
                Button(action: onRebook) {
                    Label("Rezervuoti iš naujo", systemImage: "arrow.trianglehead.clockwise")
                }
                .buttonStyle(QuietButtonStyle(tint: Palette.forest))
            }
        }
    }
}
