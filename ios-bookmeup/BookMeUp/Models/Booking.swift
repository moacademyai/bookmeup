import Foundation

/// One appointment. The same record powers the client's booking list and the
/// specialist's day schedule, so a client action always has an employee consequence.
nonisolated struct Booking: Identifiable, Codable, Hashable {
    let id: UUID
    let providerID: UUID
    let providerName: String
    /// Who performs the visit. Mutable because a booking can be handed to a colleague
    /// by dragging it into their calendar column.
    var specialistName: String
    let address: String
    let imageName: String
    var serviceName: String
    var start: Date
    var durationMinutes: Int
    var price: Double
    var status: BookingStatus
    var clientName: String
    /// The client record this appointment belongs to.
    ///
    /// Optional because appointments created before the client base linked by id — and
    /// anything typed straight into the calendar — still identify a person by name.
    /// Read it through `BookMeUpStore.client(for:)`, which prefers this id and only
    /// falls back to the name link when it is missing.
    var clientID: UUID?
    var clientNote: String
    var visitNumber: Int
    var previousVisit: Date?

    init(
        id: UUID = UUID(),
        providerID: UUID,
        providerName: String,
        specialistName: String,
        address: String,
        imageName: String,
        serviceName: String,
        start: Date,
        durationMinutes: Int,
        price: Double,
        status: BookingStatus,
        clientName: String,
        clientID: UUID? = nil,
        clientNote: String = "",
        visitNumber: Int = 1,
        previousVisit: Date? = nil
    ) {
        self.id = id
        self.providerID = providerID
        self.providerName = providerName
        self.specialistName = specialistName
        self.address = address
        self.imageName = imageName
        self.serviceName = serviceName
        self.start = start
        self.durationMinutes = durationMinutes
        self.price = price
        self.status = status
        self.clientName = clientName
        self.clientID = clientID
        self.clientNote = clientNote
        self.visitNumber = visitNumber
        self.previousVisit = previousVisit
    }

    var end: Date { start.addingTimeInterval(TimeInterval(durationMinutes * 60)) }

    var durationText: String { "\(durationMinutes) min." }
}
