import Foundation

/// A visit the client did not honour.
nonisolated enum ClientAttendanceKind: String, Codable, Hashable, CaseIterable {
    /// Booked, never arrived.
    case noShow
    /// Cancelled too late for the time to be resold.
    case lateCancellation

    var title: String {
        switch self {
        case .noShow: "Neatvyko"
        case .lateCancellation: "Vėlyvas atšaukimas"
        }
    }

    var symbolName: String {
        switch self {
        case .noShow: "person.fill.xmark"
        case .lateCancellation: "clock.badge.xmark"
        }
    }
}

/// One recorded no-show or late cancellation, kept in the client's own history.
///
/// Separate from `Booking` on purpose: the booking record describes what was
/// scheduled, this describes what the client actually did.
nonisolated struct ClientAttendanceEvent: Identifiable, Hashable, Codable {
    let id: UUID
    let clientID: UUID
    let date: Date
    let kind: ClientAttendanceKind
    let serviceName: String

    init(
        id: UUID = UUID(),
        clientID: UUID,
        date: Date,
        kind: ClientAttendanceKind,
        serviceName: String
    ) {
        self.id = id
        self.clientID = clientID
        self.date = date
        self.kind = kind
        self.serviceName = serviceName
    }
}
