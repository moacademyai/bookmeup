import Foundation

/// What a question asks the client to do.
nonisolated enum ExperienceQuestionKind: String, Codable, Hashable {
    case singleSelect
    case multiSelect
    case text
}

/// One selectable answer.
///
/// `id` is the stable value written to the profile. `title` is only for display, so a
/// translation or a wording change never rewrites stored client data.
nonisolated struct ExperienceOption: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String?
    let symbolName: String?

    init(id: String, title: String, detail: String? = nil, symbolName: String? = nil) {
        self.id = id
        self.title = title
        self.detail = detail
        self.symbolName = symbolName
    }
}

/// A configurable Client Experience question.
///
/// The seven V1 questions are instances of this type, not seven separate screens. A new
/// question — or a business-specific one — is a new instance with a stable `id` and a
/// `displayOrder`; the renderer, the onboarding flow and the profile editor pick it up
/// without any of them being rebuilt.
nonisolated struct ExperienceQuestion: Identifiable, Hashable {
    let id: String
    let kind: ExperienceQuestionKind
    let title: String
    let subtitle: String?
    let options: [ExperienceOption]
    let isRequired: Bool
    let displayOrder: Int
    let isActive: Bool
    /// Placeholder for `.text` questions.
    let placeholder: String?
    /// Which business this question belongs to. `nil` means it applies everywhere —
    /// the shape that lets a future Owner builder add business-only questions.
    let businessID: UUID?

    init(
        id: String,
        kind: ExperienceQuestionKind,
        title: String,
        subtitle: String? = nil,
        options: [ExperienceOption] = [],
        isRequired: Bool = true,
        displayOrder: Int,
        isActive: Bool = true,
        placeholder: String? = nil,
        businessID: UUID? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.options = options
        self.isRequired = isRequired
        self.displayOrder = displayOrder
        self.isActive = isActive
        self.placeholder = placeholder
        self.businessID = businessID
    }

    var allowsMultiple: Bool { kind == .multiSelect }

    func option(with id: String) -> ExperienceOption? {
        options.first { $0.id == id }
    }
}

/// Stable question identifiers.
///
/// Answers are stored under these keys, so they are part of the data contract and must
/// not be renamed once a client has answered.
nonisolated enum ExperienceQuestionID {
    static let serviceInterests = "service_interests"
    static let consultation = "consultation"
    static let visitPriorities = "visit_priorities"
    static let communication = "communication"
    static let productRecommendations = "product_recommendations"
    static let additionalNote = "additional_note"
    static let hospitality = "hospitality"
}
