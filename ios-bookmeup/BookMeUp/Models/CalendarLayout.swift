import Foundation
import SwiftUI

/// Which timeline the specialist is looking at.
nonisolated enum CalendarScope: String, CaseIterable, Identifiable {
    case mine
    case team

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mine: "Mano kalendorius"
        case .team: "Komandos kalendorius"
        }
    }

    /// Fits the segmented control.
    var shortTitle: String {
        switch self {
        case .mine: "Mano"
        case .team: "Komanda"
        }
    }
}

/// One thing occupying time on a calendar column: an appointment or personal time.
nonisolated enum CalendarItem: Identifiable, Hashable {
    case booking(Booking)
    case block(TimeBlock)

    var id: UUID {
        switch self {
        case .booking(let booking): booking.id
        case .block(let block): block.id
        }
    }

    var start: Date {
        switch self {
        case .booking(let booking): booking.start
        case .block(let block): block.start
        }
    }

    var minutes: Int {
        switch self {
        case .booking(let booking): booking.durationMinutes
        case .block(let block): block.durationMinutes
        }
    }

    var end: Date { start.addingTimeInterval(TimeInterval(minutes * 60)) }
}

/// An item after overlap resolution: which lane it sits in and how many lanes share its cluster.
nonisolated struct PositionedCalendarItem: Identifiable {
    let item: CalendarItem
    let lane: Int
    let laneCount: Int

    var id: UUID { item.id }
}

/// Geometry and time math for the day timeline. Pure layout — no booking rules here.
nonisolated enum CalendarLayout {
    static let dayStartHour = 8
    static let dayEndHour = 20
    static let hourHeight: CGFloat = 76
    static let snapMinutes = 15
    static let railWidth: CGFloat = 54
    static let minimumBlockHeight: CGFloat = 28

    static var minuteHeight: CGFloat { hourHeight / 60 }
    static var totalMinutes: Int { (dayEndHour - dayStartHour) * 60 }
    static var totalHeight: CGFloat { CGFloat(totalMinutes) * minuteHeight }

    /// Half-hour marks from the opening time to closing time.
    static var halfHourMarks: [Int] { Array(stride(from: 0, through: totalMinutes, by: 30)) }

    static func dayStart(_ day: Date) -> Date {
        AppDate.calendar.date(bySettingHour: dayStartHour, minute: 0, second: 0, of: day) ?? day
    }

    static func label(forMinutesFromStart minutes: Int) -> String {
        let hour = dayStartHour + minutes / 60
        let minute = minutes % 60
        return String(format: "%02d:%02d", hour, minute)
    }

    static func minutesFromStart(of date: Date, on day: Date) -> Int {
        Int(date.timeIntervalSince(dayStart(day)) / 60)
    }

    static func offset(for date: Date, on day: Date) -> CGFloat {
        CGFloat(minutesFromStart(of: date, on: day)) * minuteHeight
    }

    static func height(forMinutes minutes: Int) -> CGFloat {
        max(CGFloat(minutes) * minuteHeight, minimumBlockHeight)
    }

    /// Converts a vertical touch position into a snapped time inside the working day.
    static func time(atOffset offset: CGFloat, on day: Date) -> Date {
        let rawMinutes = Int(offset / minuteHeight)
        let snapped = (rawMinutes / snapMinutes) * snapMinutes
        let clamped = min(max(snapped, 0), totalMinutes - snapMinutes)
        return dayStart(day).addingTimeInterval(TimeInterval(clamped * 60))
    }

    /// The Monday that starts the week containing `date`.
    static func weekStart(for date: Date) -> Date {
        let components = AppDate.calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return AppDate.calendar.date(from: components) ?? AppDate.startOfDay(date)
    }

    static func addingDays(_ days: Int, to date: Date) -> Date {
        AppDate.calendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    /// Places overlapping items side by side so nothing is hidden.
    static func position(_ items: [CalendarItem]) -> [PositionedCalendarItem] {
        let sorted = items.sorted { $0.start < $1.start }
        var result: [PositionedCalendarItem] = []
        var cluster: [CalendarItem] = []
        var clusterEnd: Date?

        func flush() {
            guard !cluster.isEmpty else { return }
            var laneEnds: [Date] = []
            var lanes: [UUID: Int] = [:]
            for item in cluster {
                if let index = laneEnds.firstIndex(where: { $0 <= item.start }) {
                    laneEnds[index] = item.end
                    lanes[item.id] = index
                } else {
                    laneEnds.append(item.end)
                    lanes[item.id] = laneEnds.count - 1
                }
            }
            let count = max(laneEnds.count, 1)
            for item in cluster {
                result.append(
                    PositionedCalendarItem(item: item, lane: lanes[item.id] ?? 0, laneCount: count)
                )
            }
            cluster = []
            clusterEnd = nil
        }

        for item in sorted {
            if let end = clusterEnd, item.start >= end {
                flush()
            }
            cluster.append(item)
            clusterEnd = max(clusterEnd ?? item.end, item.end)
        }
        flush()
        return result
    }
}

/// Neutral, system-native surface set used by the calendar only.
nonisolated enum CalendarTheme {
    static let background = Color(.systemGroupedBackground)
    static let canvas = Color(.systemBackground)
    static let surface = Color(.secondarySystemGroupedBackground)
    static let hairline = Color(.separator)
    static let softLine = Color(.separator).opacity(0.45)
    static let label = Color(.label)
    static let secondary = Color(.secondaryLabel)
    static let tertiary = Color(.tertiaryLabel)
    static let fill = Color(.tertiarySystemFill)
    static let accent = Color(.systemBlue)
    static let now = Color(.systemRed)
    /// A barely-there wash on a colleague's column, so the signed-in specialist's own
    /// column reads as the plain one. Subtle by design — separation is the hairline's job.
    static let ownColumnTint = Color(.secondarySystemBackground).opacity(0.5)
}
