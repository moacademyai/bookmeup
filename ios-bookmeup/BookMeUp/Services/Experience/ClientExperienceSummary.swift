import Foundation

/// One line of the specialist-facing summary.
nonisolated struct ExperienceSummaryLine: Identifiable, Hashable {
    let id: String
    let symbolName: String
    /// What the client chose, in their own words where they wrote it.
    let text: String
    /// What the line is about, e.g. "Bendravimas". Shown only in the fuller layout.
    let caption: String
    /// True for the free-text answer, which is rendered differently: it is the client
    /// speaking, not a preference we categorised.
    let isClientWritten: Bool

    init(id: String, symbolName: String, text: String, caption: String, isClientWritten: Bool = false) {
        self.id = id
        self.symbolName = symbolName
        self.text = text
        self.caption = caption
        self.isClientWritten = isClientWritten
    }
}

/// Turns a Client Experience Profile into something a specialist can read in seconds.
///
/// The specialist never sees the raw questionnaire. Unanswered questions produce no
/// line at all, so the summary is always as short as the client's actual answers.
///
/// Wording rule: every line describes a preference the client chose. Nothing here may
/// be phrased as a judgement about the person.
nonisolated enum ClientExperienceSummary {

    /// The compact lines shown before an appointment, in priority order for a specialist
    /// about to start: what to prepare, how to talk, how much to advise, what matters.
    static func lines(
        for profile: ClientExperienceProfile?,
        hospitalityOptions: [HospitalityOption]
    ) -> [ExperienceSummaryLine] {
        guard let profile else { return [] }
        var lines: [ExperienceSummaryLine] = []

        if let drink = hospitality(profile: profile, options: hospitalityOptions) {
            lines.append(drink)
        }

        if let communication = profile.communicationPreference {
            lines.append(
                ExperienceSummaryLine(
                    id: ExperienceQuestionID.communication,
                    symbolName: communication.symbolName,
                    text: communication.title,
                    caption: "Bendravimas"
                )
            )
        }

        if let consultation = profile.consultationPreference {
            lines.append(
                ExperienceSummaryLine(
                    id: ExperienceQuestionID.consultation,
                    symbolName: consultation.symbolName,
                    text: consultation.title,
                    caption: "Konsultacija"
                )
            )
        }

        let priorities = profile.visitPriorities
        if !priorities.isEmpty {
            lines.append(
                ExperienceSummaryLine(
                    id: ExperienceQuestionID.visitPriorities,
                    symbolName: "sparkles",
                    text: priorities.map(\.title).joined(separator: " · "),
                    caption: "Svarbiausia"
                )
            )
        }

        if let products = profile.productRecommendationPreference {
            lines.append(
                ExperienceSummaryLine(
                    id: ExperienceQuestionID.productRecommendations,
                    symbolName: "bag",
                    text: productText(products),
                    caption: "Produktai"
                )
            )
        }

        if let note = profile.additionalPreferenceNote {
            lines.append(
                ExperienceSummaryLine(
                    id: ExperienceQuestionID.additionalNote,
                    symbolName: "quote.bubble",
                    text: note,
                    caption: "Kliento žinutė",
                    isClientWritten: true
                )
            )
        }

        return lines
    }

    /// The fuller layout adds the client's service interests, which help a conversation
    /// but say nothing about the visit that is starting.
    static func detailedLines(
        for profile: ClientExperienceProfile?,
        hospitalityOptions: [HospitalityOption]
    ) -> [ExperienceSummaryLine] {
        guard let profile else { return [] }
        var lines = self.lines(for: profile, hospitalityOptions: hospitalityOptions)

        let categories = profile.interestedCategories
        if !categories.isEmpty {
            lines.append(
                ExperienceSummaryLine(
                    id: ExperienceQuestionID.serviceInterests,
                    symbolName: "square.grid.2x2",
                    text: categories.map(\.title).joined(separator: " · "),
                    caption: "Domina paslaugos"
                )
            )
        }
        return lines
    }

    // MARK: - Private

    private static func hospitality(
        profile: ClientExperienceProfile,
        options: [HospitalityOption]
    ) -> ExperienceSummaryLine? {
        guard let id = profile.hospitalityOptionID,
              let option = options.first(where: { $0.id == id }) else { return nil }
        return ExperienceSummaryLine(
            id: ExperienceQuestionID.hospitality,
            symbolName: option.symbolName,
            text: option.id == HospitalityOption.declined.id ? "Gėrimo nereikia" : option.title,
            caption: "Vaišės"
        )
    }

    /// Phrased as an instruction to the specialist, because that is what it is for.
    private static func productText(_ preference: ProductRecommendationPreference) -> String {
        switch preference {
        case .yes: "Rekomendacijos laukiamos"
        case .onlyIfRelevant: "Siūlyti tik jei tikrai tinka"
        case .no: "Produktų nesiūlyti"
        }
    }
}
