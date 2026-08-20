import Foundation

/// Demo Client Experience content.
///
/// Two clients already answered the questionnaire so the specialist side can be tested
/// the moment the app launches. The signed-in demo client deliberately has **no**
/// profile — that is what makes onboarding appear on a fresh install.
///
/// Nothing here is read by a view. The store serves profiles per client, exactly like
/// bookings and passport records.
nonisolated extension SampleData {

    /// The authenticated client of the demo session.
    ///
    /// The number matches an existing record in `clientDirectory`, which is the point:
    /// signing in has to find that person, not create a second one.
    static var demoAccount: ClientAccount {
        ClientAccount(
            accountID: "demo-client-account",
            firstName: "Ieva",
            lastName: "Kazlauskaitė",
            phone: "+370 612 34 507",
            email: "ieva@example.lt"
        )
    }

    static var experienceProfiles: [ClientExperienceProfile] {
        [
            experienceProfile(
                "C0000001",
                client: "Kipras Adomaitis",
                categories: [ServiceCategory.beauty.rawValue],
                consultation: .wantsRecommendations,
                priorities: [.result, .comfort],
                communication: .social,
                products: .onlyIfRelevant,
                note: "Skubu tik penktadieniais — kitomis dienomis laiko turiu.",
                hospitality: "coffee"
            ),
            experienceProfile(
                "C0000002",
                client: "Lina Petrauskaitė",
                categories: [ServiceCategory.beauty.rawValue, ServiceCategory.wellness.rawValue],
                consultation: .knowsWhatTheyWant,
                priorities: [.speed],
                communication: .quiet,
                products: .no,
                note: nil,
                hospitality: "water"
            )
        ].compactMap { $0 }
    }

    private static func experienceProfile(
        _ seed: String,
        client: String,
        categories: [String],
        consultation: ConsultationPreference,
        priorities: [VisitPriority],
        communication: CommunicationPreference,
        products: ProductRecommendationPreference,
        note: String?,
        hospitality: String
    ) -> ClientExperienceProfile? {
        guard let id = clientID(for: client) else { return nil }
        var answers: [String: ExperienceAnswer] = [
            ExperienceQuestionID.serviceInterests: .selection(Set(categories)),
            ExperienceQuestionID.consultation: .selection([consultation.rawValue]),
            ExperienceQuestionID.visitPriorities: .selection(Set(priorities.map(\.rawValue))),
            ExperienceQuestionID.communication: .selection([communication.rawValue]),
            ExperienceQuestionID.productRecommendations: .selection([products.rawValue]),
            ExperienceQuestionID.hospitality: .selection([hospitality])
        ]
        if let note {
            answers[ExperienceQuestionID.additionalNote] = .text(note)
        }
        return ClientExperienceProfile(
            id: UUID(uuidString: "\(seed)-0000-4000-8000-000000000000") ?? UUID(),
            clientID: id,
            businessID: OwnerSampleData.businessID,
            answers: answers,
            onboardingCompleted: true,
            onboardingCompletedAt: AppDate.time(10, 0, dayOffset: -30),
            updatedAt: AppDate.time(10, 0, dayOffset: -30)
        )
    }
}
