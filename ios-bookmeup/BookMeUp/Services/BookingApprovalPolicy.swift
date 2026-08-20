import Foundation

/// The single rule that decides whether a new appointment can be confirmed on the spot.
///
/// A normal appointment is always confirmed immediately — the specialist should not
/// have to approve routine work. Manual approval exists only for clients whose own
/// history shows repeated no-shows.
///
/// Every screen and every booking entry point asks this type, so the rule can be
/// changed here once instead of being re-implemented per view.
nonisolated enum BookingApprovalPolicy {
    /// From how many recorded no-shows a client's new bookings need approval.
    static let noShowThreshold = 2

    /// True when this history means new bookings must be approved by the specialist.
    static func requiresApproval(noShowCount: Int) -> Bool {
        noShowCount >= noShowThreshold
    }

    /// The status a newly created appointment starts with.
    static func status(noShowCount: Int) -> BookingStatus {
        requiresApproval(noShowCount: noShowCount) ? .pending : .confirmed
    }
}
