import Foundation

/// How one client prefers to be served.
///
/// This is the single source of truth for the Client Experience answers. The client
/// environment writes it, the specialist environment reads it, and nothing copies the
/// values anywhere else — so an edit in the client profile is visible in the booking
/// detail and the client 360 the moment it is saved.
///
/// Answers live in one keyed dictionary so a new question never changes this type, and
/// the typed accessors below give business logic real Swift values instead of strings.
///
/// Privacy: this record holds preferences the client chose to share to improve their
/// visit. It must never be mixed with no-show risk, payment history, internal reputation,
/// employee private notes or anything medical.
nonisolated struct ClientExperienceProfile: Identifiable, Codable, Hashable {
    let id: UUID
    /// The real client record this belongs to — never a name string.
    let clientID: UUID
    /// Which business the business-scoped answers were given for. `nil` means the
    /// profile is not tied to one business yet; the field exists so a client who later
    /// visits a second business can keep global answers and get business-specific ones.
    var businessID: UUID?
    /// questionID → answer.
    var answers: [String: ExperienceAnswer]
    var onboardingCompleted: Bool
    var onboardingCompletedAt: Date?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        clientID: UUID,
        businessID: UUID? = nil,
        answers: [String: ExperienceAnswer] = [:],
        onboardingCompleted: Bool = false,
        onboardingCompletedAt: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.clientID = clientID
        self.businessID = businessID
        self.answers = answers
        self.onboardingCompleted = onboardingCompleted
        self.onboardingCompletedAt = onboardingCompletedAt
        self.updatedAt = updatedAt
    }

    func answer(for questionID: String) -> ExperienceAnswer? {
        guard let stored = answers[questionID], !stored.isEmpty else { return nil }
        return stored
    }

    /// True when the client has actually shared something worth showing a specialist.
    var hasSharedPreferences: Bool {
        answers.values.contains { !$0.isEmpty }
    }
}

// MARK: - Typed accessors

extension ClientExperienceProfile {
    /// Stable service category ids. Kept as ids rather than `ServiceCategory` values so
    /// a platform that later adds categories does not invalidate stored answers.
    var interestedCategoryIDs: [String] {
        answer(for: ExperienceQuestionID.serviceInterests)?.optionIDs.sorted() ?? []
    }

    /// The categories that resolve to something this build knows about.
    var interestedCategories: [ServiceCategory] {
        interestedCategoryIDs.compactMap { ServiceCategory(rawValue: $0) }
    }

    var consultationPreference: ConsultationPreference? {
        answer(for: ExperienceQuestionID.consultation)?
            .singleOptionID
            .flatMap(ConsultationPreference.init(rawValue:))
    }

    /// Ordered by the enum, not by the order the client happened to tap.
    var visitPriorities: [VisitPriority] {
        let ids = answer(for: ExperienceQuestionID.visitPriorities)?.optionIDs ?? []
        return VisitPriority.allCases.filter { ids.contains($0.rawValue) }
    }

    var communicationPreference: CommunicationPreference? {
        answer(for: ExperienceQuestionID.communication)?
            .singleOptionID
            .flatMap(CommunicationPreference.init(rawValue:))
    }

    var productRecommendationPreference: ProductRecommendationPreference? {
        answer(for: ExperienceQuestionID.productRecommendations)?
            .singleOptionID
            .flatMap(ProductRecommendationPreference.init(rawValue:))
    }

    /// Something the client chose to tell the specialist. Not a booking note, not an
    /// internal note, not medical information.
    var additionalPreferenceNote: String? {
        answer(for: ExperienceQuestionID.additionalNote)?.textValue
    }

    /// Stable hospitality option id. The title is resolved from the business options,
    /// because the catalogue of drinks belongs to the business, not to the platform.
    var hospitalityOptionID: String? {
        answer(for: ExperienceQuestionID.hospitality)?.singleOptionID
    }
}
