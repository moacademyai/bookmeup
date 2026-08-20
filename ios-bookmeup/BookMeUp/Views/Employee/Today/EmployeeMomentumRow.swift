import SwiftUI

/// The three numbers that describe how strong the schedule ahead is.
///
/// Deliberately not three cards: a hairline between columns carries the separation,
/// so the numbers stay the loudest thing on the row instead of the containers around
/// them. Only the first column is interactive, because only it has more to say.
struct EmployeeMomentumRow: View {
    let momentum: EmployeeMomentum
    var onOpenUpcoming: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 0) {
                Button(action: onOpenUpcoming) {
                    column(
                        value: "\(momentum.upcomingAppointments)",
                        caption: "Būsimi vizitai",
                        showsChevron: momentum.upcomingAppointments > 0
                    )
                }
                .buttonStyle(.plain)
                .disabled(momentum.upcomingAppointments == 0)

                separator

                column(
                    value: momentum.weekOccupancyText,
                    caption: "Užimtumas · 7 d.",
                    showsChevron: false
                )

                separator

                column(
                    value: "\(momentum.strongDaysAhead) d.",
                    caption: "Užbookinta į priekį",
                    showsChevron: false
                )
            }

            if let change = momentum.changeText {
                Text(change)
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
            }
        }
    }

    private func column(value: String, caption: String, showsChevron: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(value)
                    .font(.title2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Palette.inkSoft.opacity(0.6))
                }
            }
            Text(caption)
                .font(.caption)
                .foregroundStyle(Palette.inkSoft)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }

    private var separator: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(width: 1, height: 34)
            .padding(.horizontal, 10)
    }
}
