import Foundation

nonisolated enum MessageChannel: String, CaseIterable, Identifiable, Hashable, Codable {
    case sms
    case push
    case email
    case inApp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sms: "SMS"
        case .push: "Push"
        case .email: "El. paštas"
        case .inApp: "Programėlėje"
        }
    }

    var symbolName: String {
        switch self {
        case .sms: "message"
        case .push: "bell.badge"
        case .email: "envelope"
        case .inApp: "bubble.left"
        }
    }
}

/// What makes a message go out. Timing is stored separately, so "24 h before the
/// visit" and "2 h before the visit" are the same trigger with a different offset.
nonisolated enum MessageTrigger: String, CaseIterable, Identifiable, Hashable, Codable {
    case bookingConfirmed
    case bookingReminder
    case bookingRescheduled
    case bookingCancelled
    case clientLate
    case noShowRecorded
    case waitlistSlotFree
    case readyEarlier
    case afterHoursOffer
    case reviewRequest
    case outcomeRequest
    case aftercare
    case fixIt
    case rebooking
    case winBack
    case birthday
    case loyalty
    case referral
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bookingConfirmed: "Rezervacijos patvirtinimas"
        case .bookingReminder: "Priminimas apie vizitą"
        case .bookingRescheduled: "Laiko pakeitimas"
        case .bookingCancelled: "Atšaukimas"
        case .clientLate: "Klientas vėluoja"
        case .noShowRecorded: "Neatvykimas"
        case .waitlistSlotFree: "Atsilaisvino laikas"
        case .readyEarlier: "Galime priimti anksčiau"
        case .afterHoursOffer: "Po darbo valandų"
        case .reviewRequest: "Prašymas įvertinti"
        case .outcomeRequest: "Rezultato vertinimas"
        case .aftercare: "Priežiūra po vizito"
        case .fixIt: "Fix It"
        case .rebooking: "Kvietimas registruotis"
        case .winBack: "Grįžimo kvietimas"
        case .birthday: "Gimtadienis"
        case .loyalty: "Lojalumas"
        case .referral: "Rekomendacija"
        case .custom: "Individuali žinutė"
        }
    }

    /// Operational messages go out regardless of marketing consent; everything that
    /// sells requires it. The split is a legal requirement, not a preference.
    var isMarketing: Bool {
        switch self {
        case .rebooking, .winBack, .birthday, .loyalty, .referral, .afterHoursOffer, .custom:
            true
        default:
            false
        }
    }
}

/// Placeholders a template may use. Kept as a closed list so a preview can always
/// be rendered and a typo never ships as literal text to a client.
nonisolated enum MessageVariable: String, CaseIterable, Identifiable, Hashable {
    case clientFirstName = "client_first_name"
    case employeeName = "employee_name"
    case serviceName = "service_name"
    case appointmentDate = "appointment_date"
    case appointmentTime = "appointment_time"
    case businessName = "business_name"
    case locationName = "location_name"
    case bookingLink = "booking_link"

    var id: String { rawValue }

    var token: String { "{{\(rawValue)}}" }
}

/// One configured message. No provider is named anywhere: sending will go through a
/// messaging service abstraction, so SMS, push and email share this shape.
nonisolated struct MessageTemplate: Identifiable, Hashable, Codable {
    let id: UUID
    var trigger: MessageTrigger
    var title: String
    var channels: Set<MessageChannel>
    var isEnabled: Bool
    /// Minutes relative to the trigger. Negative is before, positive is after.
    var offsetMinutes: Int
    var body: String
    var respectsQuietHours: Bool

    init(
        id: UUID = UUID(),
        trigger: MessageTrigger,
        title: String,
        channels: Set<MessageChannel>,
        isEnabled: Bool = true,
        offsetMinutes: Int = 0,
        body: String = "",
        respectsQuietHours: Bool = true
    ) {
        self.id = id
        self.trigger = trigger
        self.title = title
        self.channels = channels
        self.isEnabled = isEnabled
        self.offsetMinutes = offsetMinutes
        self.body = body
        self.respectsQuietHours = respectsQuietHours
    }

    var requiresMarketingConsent: Bool { trigger.isMarketing }

    var timingText: String {
        if offsetMinutes == 0 { return "Iš karto" }
        let hours = abs(offsetMinutes) / 60
        let value = hours >= 1 ? "\(hours) val." : "\(abs(offsetMinutes)) min."
        return offsetMinutes < 0 ? "\(value) prieš" : "\(value) po"
    }

    var channelText: String {
        MessageChannel.allCases
            .filter { channels.contains($0) }
            .map(\.title)
            .joined(separator: " · ")
    }
}

/// Why a client stopped coming. Structured on purpose: free text cannot be counted,
/// and the owner needs the count more than the prose.
nonisolated enum ChurnReason: String, CaseIterable, Identifiable, Hashable, Codable {
    case tooExpensive
    case resultNotLiked
    case serviceNotLiked
    case inconvenientLocation
    case moved
    case foundAnotherSpecialist
    case needLessOften
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tooExpensive: "Per brangu"
        case .resultNotLiked: "Nepatiko rezultatas"
        case .serviceNotLiked: "Nepatiko aptarnavimas"
        case .inconvenientLocation: "Nepatogi vieta"
        case .moved: "Persikėliau"
        case .foundAnotherSpecialist: "Radau kitą specialistą"
        case .needLessOften: "Nereikia taip dažnai"
        case .other: "Kita"
        }
    }
}

/// What the owner may offer a client who is drifting away.
nonisolated enum WinBackIncentive: String, CaseIterable, Identifiable, Hashable, Codable {
    case none
    case loyaltyBonus
    case prioritySlot
    case discount

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "Tik priminimas"
        case .loyaltyBonus: "Lojalumo taškai"
        case .prioritySlot: "Pirmumas geram laikui"
        case .discount: "Leidžiama nuolaida"
        }
    }
}

/// Bringing clients back.
///
/// The days are settings, never constants in business logic: the intent is that the
/// system leans on each client's own return cycle first and falls back to these only
/// when there is not enough history to know it.
nonisolated struct RetentionSettings: Hashable, Codable {
    var usesIndividualReturnCycle: Bool
    /// Gentle nudge, counted from the last visit.
    var missYouAfterDays: Int
    /// Stronger win-back.
    var winBackAfterDays: Int
    var winBackIncentive: WinBackIncentive
    /// Structured questionnaire for clients who still do not come back.
    var asksChurnReason: Bool
    var rewardsQuestionnaireWithPoints: Bool
    var questionnairePoints: Int
    var respectsMarketingConsent: Bool
    var respectsQuietHours: Bool

    static let standard = RetentionSettings(
        usesIndividualReturnCycle: true,
        missYouAfterDays: 45,
        winBackAfterDays: 60,
        winBackIncentive: .loyaltyBonus,
        asksChurnReason: true,
        rewardsQuestionnaireWithPoints: true,
        questionnairePoints: 50,
        respectsMarketingConsent: true,
        respectsQuietHours: true
    )
}
