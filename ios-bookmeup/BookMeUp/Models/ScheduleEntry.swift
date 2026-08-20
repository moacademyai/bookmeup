import Foundation

/// One row of the specialist's day: a real appointment, a personal block, or a free gap.
nonisolated enum ScheduleEntry: Identifiable, Hashable {
    case booking(Booking)
    case block(TimeBlock)
    case free(id: UUID, start: Date, minutes: Int)

    var id: String {
        switch self {
        case .booking(let booking): "booking-\(booking.id.uuidString)"
        case .block(let block): "block-\(block.id.uuidString)"
        case .free(let id, _, _): "free-\(id.uuidString)"
        }
    }

    var start: Date {
        switch self {
        case .booking(let booking): booking.start
        case .block(let block): block.start
        case .free(_, let start, _): start
        }
    }

    var minutes: Int {
        switch self {
        case .booking(let booking): booking.durationMinutes
        case .block(let block): block.durationMinutes
        case .free(_, _, let minutes): minutes
        }
    }
}
