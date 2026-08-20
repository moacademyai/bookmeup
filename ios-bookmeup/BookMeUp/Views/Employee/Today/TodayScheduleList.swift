import SwiftUI

/// Today's appointments as a quiet timeline.
///
/// Time on the left, client and service in the middle, status only when it is not
/// the ordinary one. A row opens the existing appointment screen — none of the
/// actions on that screen are duplicated here.
struct TodayScheduleList: View {
    let appointments: [Booking]
    var onOpen: (Booking) -> Void

    var body: some View {
        if appointments.isEmpty {
            Text("Šiandien vizitų nėra.")
                .font(.subheadline)
                .foregroundStyle(Palette.inkSoft)
                .padding(.vertical, 6)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(appointments.enumerated()), id: \.element.id) { index, booking in
                    Button {
                        onOpen(booking)
                    } label: {
                        row(booking)
                    }
                    .buttonStyle(TodayRowStyle())

                    if index < appointments.count - 1 {
                        Divider()
                            .overlay(Palette.hairline)
                            .padding(.leading, 62)
                    }
                }
            }
        }
    }

    private func row(_ booking: Booking) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(booking.start.timeText)
                .font(.subheadline.weight(.medium).monospacedDigit())
                .foregroundStyle(isPast(booking) ? Palette.inkSoft : Palette.ink)
                .frame(width: 48, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(booking.clientName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isPast(booking) ? Palette.inkSoft : Palette.ink)
                    .lineLimit(1)
                Text("\(booking.serviceName) · \(booking.durationText)")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                // Confirmed is the normal state and says nothing worth a line of type.
                if booking.status != .confirmed {
                    Text(booking.status.title)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(booking.status.tint)
                }
            }

            Spacer(minLength: 4)
        }
        .padding(.vertical, 13)
        .contentShape(.rect)
    }

    private func isPast(_ booking: Booking) -> Bool { booking.end <= Date() }
}

/// A row that dims on press instead of scaling — nothing on this screen bounces.
private struct TodayRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed ? Palette.hairline.opacity(0.5) : .clear,
                in: .rect(cornerRadius: 10)
            )
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
