import SwiftUI

/// Shown after a long press on free time: appointment or block, nothing else.
struct CalendarQuickCreateSheet: View {
    let time: Date
    /// Whose column was pressed. Carried all the way into the booking so helping a
    /// colleague never quietly books the visit into the wrong calendar.
    let specialistName: String
    var isColleague: Bool = false
    var onChoose: (CalendarQuickChoice) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(time.timeText)
                    .font(.largeTitle.weight(.bold).monospacedDigit())
                    .foregroundStyle(CalendarTheme.label)
                Text(time.weekdayLongText)
                    .font(.subheadline)
                    .foregroundStyle(CalendarTheme.secondary)
                // Named only when it is somebody else's calendar, because that is the
                // only time the answer is not obvious.
                if isColleague {
                    Text(specialistName)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(CalendarTheme.accent)
                        .padding(.top, 2)
                }
            }
            .padding(.top, 22)

            VStack(spacing: 10) {
                choiceButton(
                    title: "Rezervacija",
                    detail: "Klientas ir paslauga",
                    symbol: "calendar.badge.plus",
                    choice: .appointment
                )
                choiceButton(
                    title: "Blokas",
                    detail: "Asmeninis laikas",
                    symbol: "clock.badge.xmark",
                    choice: .block
                )
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .background(CalendarTheme.background)
        .presentationDetents([.height(isColleague ? 306 : 280)])
        .presentationDragIndicator(.visible)
    }

    private func choiceButton(
        title: String,
        detail: String,
        symbol: String,
        choice: CalendarQuickChoice
    ) -> some View {
        Button {
            onChoose(choice)
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(CalendarTheme.accent)
                    .frame(width: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(CalendarTheme.label)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(CalendarTheme.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CalendarTheme.tertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CalendarTheme.surface, in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

nonisolated enum CalendarQuickChoice {
    case appointment
    case block
}
