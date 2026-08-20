import Foundation

/// What kind of capacity a resource represents.
///
/// Deliberately generic: a chair, a room, a treatment bed and a laser device are the
/// same idea — a limited thing a service occupies for a while. Nothing in the platform
/// assumes a barber chair.
nonisolated enum ResourceType: String, CaseIterable, Identifiable, Hashable, Codable {
    case chair
    case room
    case washStation
    case treatmentBed
    case device
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chair: "Kėdė"
        case .room: "Kabinetas"
        case .washStation: "Plovimo vieta"
        case .treatmentBed: "Procedūrų gultas"
        case .device: "Įranga"
        case .custom: "Kita"
        }
    }

    var symbolName: String {
        switch self {
        case .chair: "chair.lounge"
        case .room: "door.left.hand.closed"
        case .washStation: "drop"
        case .treatmentBed: "bed.double"
        case .device: "wave.3.right"
        case .custom: "square.grid.2x2"
        }
    }
}

/// A bookable capacity unit inside a location.
///
/// Services will later declare the resources they need, which is how the calendar
/// learns that two colourings cannot share one wash station.
nonisolated struct BusinessResource: Identifiable, Hashable, Codable {
    let id: UUID
    let locationID: UUID
    var name: String
    var type: ResourceType
    /// Used when `type == .custom`, so a new market never needs a code change.
    var customTypeTitle: String?
    var isActive: Bool
    var note: String

    init(
        id: UUID = UUID(),
        locationID: UUID,
        name: String,
        type: ResourceType,
        customTypeTitle: String? = nil,
        isActive: Bool = true,
        note: String = ""
    ) {
        self.id = id
        self.locationID = locationID
        self.name = name
        self.type = type
        self.customTypeTitle = customTypeTitle
        self.isActive = isActive
        self.note = note
    }

    var typeTitle: String {
        type == .custom ? (customTypeTitle ?? ResourceType.custom.title) : type.title
    }
}
