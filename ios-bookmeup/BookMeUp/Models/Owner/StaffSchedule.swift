import Foundation

/// A recurring working block: this person, this location, this weekday.
///
/// Exceptions and leave are layered on top instead of editing the pattern, so a
/// single day off never rewrites someone's whole week.
nonisolated struct WorkShift: Identifiable, Hashable, Codable {
    let id: UUID
    let staffID: UUID
    let locationID: UUID
    /// 1 = Monday … 7 = Sunday.
    var weekday: Int
    var startMinutes: Int
    var endMinutes: Int
    var isActive: Bool

    init(
        id: UUID = UUID(),
        staffID: UUID,
        locationID: UUID,
        weekday: Int,
        startMinutes: Int,
        endMinutes: Int,
        isActive: Bool = true
    ) {
        self.id = id
        self.staffID = staffID
        self.locationID = locationID
        self.weekday = weekday
        self.startMinutes = startMinutes
        self.endMinutes = endMinutes
        self.isActive = isActive
    }

    var rangeText: String {
        "\(DayHours.timeText(startMinutes))–\(DayHours.timeText(endMinutes))"
    }

    var minutes: Int { max(endMinutes - startMinutes, 0) }
}

nonisolated enum LeaveKind: String, CaseIterable, Identifiable, Hashable, Codable {
    case dayOff
    case vacation
    case sickLeave
    case training
    case locationChange

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dayOff: "Laisva diena"
        case .vacation: "Atostogos"
        case .sickLeave: "Nedarbingumas"
        case .training: "Mokymai"
        case .locationChange: "Kita lokacija"
        }
    }

    var symbolName: String {
        switch self {
        case .dayOff: "moon.zzz"
        case .vacation: "sun.max"
        case .sickLeave: "cross.case"
        case .training: "graduationcap"
        case .locationChange: "arrow.left.arrow.right"
        }
    }
}

nonisolated enum LeaveStatus: String, CaseIterable, Identifiable, Hashable, Codable {
    case pending
    case approved
    case rejected

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending: "Laukia sprendimo"
        case .approved: "Patvirtinta"
        case .rejected: "Atmesta"
        }
    }
}

/// Time away from the floor, requested by the person and decided by whoever holds
/// `manageLeave`. Approving it will later have to show the appointments it touches —
/// the dates are kept here precisely so that check can be added without a migration.
nonisolated struct LeaveRequest: Identifiable, Hashable, Codable {
    let id: UUID
    let staffID: UUID
    var kind: LeaveKind
    var start: Date
    var end: Date
    var note: String
    var status: LeaveStatus
    var requestedAt: Date

    init(
        id: UUID = UUID(),
        staffID: UUID,
        kind: LeaveKind,
        start: Date,
        end: Date,
        note: String = "",
        status: LeaveStatus = .pending,
        requestedAt: Date = Date()
    ) {
        self.id = id
        self.staffID = staffID
        self.kind = kind
        self.start = start
        self.end = end
        self.note = note
        self.status = status
        self.requestedAt = requestedAt
    }

    var rangeText: String {
        AppDate.isSameDay(start, end) ? start.dayText : "\(start.dayText) – \(end.dayText)"
    }

    var dayCount: Int {
        max((AppDate.calendar.dateComponents([.day], from: AppDate.startOfDay(start), to: AppDate.startOfDay(end)).day ?? 0) + 1, 1)
    }
}
