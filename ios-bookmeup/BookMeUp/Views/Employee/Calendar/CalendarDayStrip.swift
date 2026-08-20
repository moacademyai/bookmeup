import SwiftUI

/// Week row with month navigation. One tap picks a day, chevrons move the week,
/// the month title opens a full date picker.
struct CalendarDayStrip: View {
    @Binding var selectedDate: Date
    var onOpenMonthPicker: () -> Void
    var onToday: () -> Void

    private var isOnToday: Bool { AppDate.calendar.isDateInToday(selectedDate) }

    private var weekStart: Date { CalendarLayout.weekStart(for: selectedDate) }

    private var days: [Date] {
        (0..<7).map { CalendarLayout.addingDays($0, to: weekStart) }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "lt_LT")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: selectedDate).capitalizedFirst
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 4) {
                Button {
                    move(by: -7)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 40, height: 34)
                        .contentShape(.rect)
                }
                .accessibilityLabel("Ankstesnė savaitė")

                Button(action: onOpenMonthPicker) {
                    HStack(spacing: 4) {
                        Text(monthTitle)
                            .font(.headline)
                            .foregroundStyle(CalendarTheme.label)
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(CalendarTheme.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)

                Button {
                    move(by: 7)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 40, height: 34)
                        .contentShape(.rect)
                }
                .accessibilityLabel("Kita savaitė")

                if !isOnToday {
                    Button(action: onToday) {
                        Text("Šiandien")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CalendarTheme.accent)
                            .padding(.horizontal, 10)
                            .frame(height: 30)
                            .background(CalendarTheme.accent.opacity(0.12), in: .capsule)
                            .contentShape(.capsule)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .animation(.easeOut(duration: 0.18), value: isOnToday)

            HStack(spacing: 4) {
                ForEach(days, id: \.timeIntervalSince1970) { day in
                    dayCell(day)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 10)
        .background(CalendarTheme.canvas)
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = AppDate.isSameDay(day, selectedDate)
        let isToday = AppDate.calendar.isDateInToday(day)
        return Button {
            withAnimation(.easeOut(duration: 0.18)) { selectedDate = day }
        } label: {
            VStack(spacing: 5) {
                Text(day.weekdayShortText.prefix(2))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(isSelected ? CalendarTheme.canvas.opacity(0.8) : CalendarTheme.secondary)
                Text(day.dayNumberText)
                    .font(.callout.weight(.semibold).monospacedDigit())
                    .foregroundStyle(dayNumberColor(isSelected: isSelected, isToday: isToday))
                Circle()
                    .fill(isToday ? (isSelected ? CalendarTheme.canvas : CalendarTheme.accent) : .clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(isSelected ? CalendarTheme.label : .clear, in: .rect(cornerRadius: 12))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.weekdayLongText)
    }

    private func dayNumberColor(isSelected: Bool, isToday: Bool) -> Color {
        if isSelected { return CalendarTheme.canvas }
        return isToday ? CalendarTheme.accent : CalendarTheme.label
    }

    private func move(by days: Int) {
        withAnimation(.easeOut(duration: 0.18)) {
            selectedDate = CalendarLayout.addingDays(days, to: selectedDate)
        }
    }
}
