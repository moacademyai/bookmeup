import Foundation

/// A recipe line inside a Beauty Passport entry.
///
/// The catalog is deliberately generic: a barber stores clipper guards and a fade
/// technique, a colorist stores a formula and a tone, a nail artist stores a shape.
/// Anything the catalog does not cover is stored as a custom titled line, so a new
/// service category never needs a model change.
nonisolated enum BeautyPassportField: String, Codable, CaseIterable, Hashable {
    case technique
    case clipperGuards
    case length
    case formula
    case tone
    case shape
    case products
    case timing
    case care

    var title: String {
        switch self {
        case .technique: "Technika"
        case .clipperGuards: "Mašinėlės numeriai"
        case .length: "Ilgis"
        case .formula: "Formulė"
        case .tone: "Atspalvis"
        case .shape: "Forma"
        case .products: "Priemonės"
        case .timing: "Laikymas"
        case .care: "Priežiūra"
        }
    }

    var symbolName: String {
        switch self {
        case .technique: "wand.and.rays"
        case .clipperGuards: "number"
        case .length: "ruler"
        case .formula: "drop"
        case .tone: "paintpalette"
        case .shape: "square.on.circle"
        case .products: "bag"
        case .timing: "timer"
        case .care: "leaf"
        }
    }
}

/// Where a passport record is in the specialist's workflow.
///
/// A record starts as a `draft` the moment the specialist opens it during the visit
/// and stays editable until it is finished. Only `completed` records surface in the
/// client's passport history.
nonisolated enum BeautyPassportStatus: String, Codable, Hashable {
    case draft
    case completed
}

/// One labelled line of the recipe. Every line is optional by nature — a service
/// only stores what it actually needs.
nonisolated struct BeautyPassportDetail: Identifiable, Codable, Hashable {
    let id: UUID
    /// Catalog field, or nil when this line uses a custom title.
    var field: BeautyPassportField?
    var customTitle: String?
    var value: String

    init(id: UUID = UUID(), field: BeautyPassportField, value: String) {
        self.id = id
        self.field = field
        self.customTitle = nil
        self.value = value
    }

    init(id: UUID = UUID(), title: String, value: String) {
        self.id = id
        self.field = nil
        self.customTitle = title
        self.value = value
    }

    var title: String { field?.title ?? customTitle ?? "" }

    var symbolName: String { field?.symbolName ?? "sparkles" }

    var hasValue: Bool { !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

/// What was actually done to this client during one visit.
///
/// The entry belongs to a `Client` and, when the visit exists as an appointment, to
/// that `Booking`. A client can have many entries — one per visit — so the passport
/// grows into a chronological record instead of overwriting itself.
///
/// Only the universal fields are stored as properties (date, service, specialist,
/// category, photos, summary, products, note). Everything service-specific lives in
/// `details`, so hair, nails, skin, brows or wellness can each store what they need
/// without a separate model.
nonisolated struct BeautyPassportEntry: Identifiable, Codable, Hashable {
    let id: UUID
    /// The client this record belongs to.
    let clientID: UUID
    /// The visit this record documents, when it is a real appointment.
    var bookingID: UUID?
    var date: Date
    var serviceName: String
    var specialistName: String
    var category: ServiceCategory
    /// Draft while the specialist is still filling it in during the visit.
    var status: BeautyPassportStatus
    /// Short human recipe shown on the client profile card.
    var summary: String
    /// Photo references, never image data — see `PassportPhotoReference`.
    var beforeImageName: String?
    var afterImageName: String?
    /// Service-specific recipe lines — empty for services that need none.
    var details: [BeautyPassportDetail]
    var products: [String]
    var specialistNote: String?

    init(
        id: UUID = UUID(),
        clientID: UUID,
        bookingID: UUID? = nil,
        date: Date,
        serviceName: String,
        specialistName: String,
        category: ServiceCategory = .beauty,
        status: BeautyPassportStatus = .completed,
        summary: String = "",
        beforeImageName: String? = nil,
        afterImageName: String? = nil,
        details: [BeautyPassportDetail] = [],
        products: [String] = [],
        specialistNote: String? = nil
    ) {
        self.id = id
        self.clientID = clientID
        self.bookingID = bookingID
        self.date = date
        self.serviceName = serviceName
        self.specialistName = specialistName
        self.category = category
        self.status = status
        self.summary = summary
        self.beforeImageName = beforeImageName
        self.afterImageName = afterImageName
        self.details = details
        self.products = products
        self.specialistNote = specialistNote
    }

    /// Recipe lines that were actually filled in.
    var filledDetails: [BeautyPassportDetail] { details.filter(\.hasValue) }

    var isDraft: Bool { status == .draft }

    /// True once the record holds anything worth keeping — used to gate finishing.
    var hasContent: Bool { hasPhotos || !filledDetails.isEmpty || note != nil || hasSummary }

    var beforePhoto: PassportPhotoReference? { PassportPhotoReference(storedValue: beforeImageName) }

    var afterPhoto: PassportPhotoReference? { PassportPhotoReference(storedValue: afterImageName) }

    var hasSummary: Bool { !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var hasPhotos: Bool { beforeImageName != nil || afterImageName != nil }

    var note: String? {
        guard let specialistNote,
              !specialistNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return specialistNote
    }
}
