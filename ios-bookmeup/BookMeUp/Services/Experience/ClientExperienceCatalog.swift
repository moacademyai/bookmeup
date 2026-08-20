import Foundation

/// Builds the Client Experience questionnaire.
///
/// This is the only place the seven V1 questions are described. The onboarding flow and
/// the profile editor both render whatever this returns, in `displayOrder`, which is why
/// there are no seven hardcoded screens anywhere in the app.
///
/// The order below is the agreed V1 order and must not be shuffled: hospitality is last
/// on purpose, so onboarding ends on a moment of service rather than on a form field.
nonisolated enum ClientExperienceCatalog {

    /// The hospitality options a business offers when nothing has been configured for it.
    ///
    /// Kept here rather than in a view so the day Owner configuration lands, only this
    /// function is replaced by a lookup.
    static func hospitalityOptions(for business: Business?) -> [HospitalityOption] {
        guard business != nil else { return [] }
        return [
            HospitalityOption(id: "coffee", title: "Kavos", symbolName: "cup.and.saucer"),
            HospitalityOption(id: "water", title: "Vandens", symbolName: "drop"),
            .declined
        ]
    }

    /// The active questionnaire for a business, already ordered.
    ///
    /// A business with no hospitality options simply has no hospitality question — the
    /// architecture the brief asks for, proven by the fact that removing the options
    /// removes the screen without touching the flow.
    static func questions(for business: Business?) -> [ExperienceQuestion] {
        let drinks = hospitalityOptions(for: business)
        return all(businessID: business?.id, hospitality: drinks)
            .filter(\.isActive)
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    /// One question by id, so a summary or an editor row can resolve its wording.
    static func question(_ id: String, for business: Business?) -> ExperienceQuestion? {
        questions(for: business).first { $0.id == id }
    }

    // MARK: - V1 definition

    private static func all(businessID: UUID?, hospitality: [HospitalityOption]) -> [ExperienceQuestion] {
        [
            serviceInterests,
            consultation,
            visitPriorities,
            communication,
            productRecommendations,
            additionalNote,
            hospitalityQuestion(businessID: businessID, options: hospitality)
        ]
    }

    /// 1 — service interests.
    ///
    /// Options come from the platform's own category list, so a marketplace that adds a
    /// category gets it here for free. Stored values are the stable category ids.
    private static var serviceInterests: ExperienceQuestion {
        ExperienceQuestion(
            id: ExperienceQuestionID.serviceInterests,
            kind: .multiSelect,
            title: "Kokios paslaugos Jus labiausiai domina?",
            subtitle: "Galite pasirinkti kelias.",
            options: ServiceCategory.allCases.map {
                ExperienceOption(id: $0.rawValue, title: $0.title, symbolName: $0.symbolName)
            },
            displayOrder: 10
        )
    }

    /// 2 — how much consultation the client wants.
    private static var consultation: ExperienceQuestion {
        ExperienceQuestion(
            id: ExperienceQuestionID.consultation,
            kind: .singleSelect,
            title: "Kiek konsultacijos norėtumėte prieš paslaugą?",
            subtitle: "Kad meistras žinotų, nuo ko pradėti.",
            options: ConsultationPreference.allCases.map {
                ExperienceOption(id: $0.rawValue, title: $0.title, detail: $0.detail, symbolName: $0.symbolName)
            },
            displayOrder: 20
        )
    }

    /// 3 — what matters most during the visit.
    private static var visitPriorities: ExperienceQuestion {
        ExperienceQuestion(
            id: ExperienceQuestionID.visitPriorities,
            kind: .multiSelect,
            title: "Kas Jums svarbiausia vizito metu?",
            subtitle: "Pasirinkite viską, kas tinka.",
            options: VisitPriority.allCases.map {
                ExperienceOption(id: $0.rawValue, title: $0.title, symbolName: $0.symbolName)
            },
            displayOrder: 30
        )
    }

    /// 4 — conversation preference.
    private static var communication: ExperienceQuestion {
        ExperienceQuestion(
            id: ExperienceQuestionID.communication,
            kind: .singleSelect,
            title: "Kaip mėgstate bendrauti vizito metu?",
            subtitle: "Nėra teisingo atsakymo — tiesiog pasakykite, kaip Jums geriau.",
            options: CommunicationPreference.allCases.map {
                ExperienceOption(id: $0.rawValue, title: $0.title, detail: $0.detail, symbolName: $0.symbolName)
            },
            displayOrder: 40
        )
    }

    /// 5 — product and aftercare suggestions. A service preference, not a marketing
    /// consent: consent lives in the profile settings and is asked separately.
    private static var productRecommendations: ExperienceQuestion {
        ExperienceQuestion(
            id: ExperienceQuestionID.productRecommendations,
            kind: .singleSelect,
            title: "Ar norite, kad meistras rekomenduotų produktus ir priežiūrą?",
            subtitle: "Tai galioja tik vizito metu. Naujienų ir pasiūlymų sutikimas nustatomas atskirai.",
            options: ProductRecommendationPreference.allCases.map {
                ExperienceOption(id: $0.rawValue, title: $0.title, detail: $0.detail, symbolName: $0.symbolName)
            },
            displayOrder: 50
        )
    }

    /// 6 — anything else, in the client's own words. Optional by design.
    private static var additionalNote: ExperienceQuestion {
        ExperienceQuestion(
            id: ExperienceQuestionID.additionalNote,
            kind: .text,
            title: "Ar yra dar kas nors, ką meistrui būtų naudinga žinoti?",
            subtitle: "Neprivaloma. Tai matys tik Jus aptarnaujantis meistras.",
            isRequired: false,
            displayOrder: 60,
            placeholder: "Pavyzdžiui: mėgstu, kai vizitas prasideda laiku"
        )
    }

    /// 7 — hospitality. Always last in V1.
    private static func hospitalityQuestion(businessID: UUID?, options: [HospitalityOption]) -> ExperienceQuestion {
        ExperienceQuestion(
            id: ExperienceQuestionID.hospitality,
            kind: .singleSelect,
            title: "Ar vizito pradžioje norėtumėte gėrimo?",
            subtitle: "Paruošime iš anksto.",
            options: options.map {
                ExperienceOption(id: $0.id, title: $0.title, symbolName: $0.symbolName)
            },
            isRequired: false,
            displayOrder: 70,
            isActive: !options.isEmpty,
            businessID: businessID
        )
    }
}
