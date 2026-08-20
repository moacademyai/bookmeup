import Foundation

/// How much a client pays up front to hold a time.
nonisolated enum DepositRule: String, CaseIterable, Identifiable, Hashable, Codable {
    case none
    case fixedAmount
    case percentage
    case fullPrepay
    case riskBased

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "Be avanso"
        case .fixedAmount: "Fiksuota suma"
        case .percentage: "Dalis nuo kainos"
        case .fullPrepay: "Visa suma iš anksto"
        case .riskBased: "Pagal kliento riziką"
        }
    }
}

nonisolated enum CancellationOutcome: String, CaseIterable, Identifiable, Hashable, Codable {
    case refund
    case credit
    case retainDeposit
    case fee
    case none

    var id: String { rawValue }

    var title: String {
        switch self {
        case .refund: "Grąžinti pinigus"
        case .credit: "Kreditas kitam vizitui"
        case .retainDeposit: "Pasilikti avansą"
        case .fee: "Taikyti mokestį"
        case .none: "Be pasekmių"
        }
    }
}

nonisolated enum NoShowConsequence: String, CaseIterable, Identifiable, Hashable, Codable {
    case none
    case fee
    case chargeCardOnFile
    case requireDeposit
    case requireFullPrepay
    case requireApproval
    case restrict

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "Be pasekmių"
        case .fee: "Neatvykimo mokestis"
        case .chargeCardOnFile: "Nuskaityti nuo išsaugotos kortelės"
        case .requireDeposit: "Kitą kartą reikalauti avanso"
        case .requireFullPrepay: "Kitą kartą pilnas išankstinis mokėjimas"
        case .requireApproval: "Kitą kartą reikia patvirtinimo"
        case .restrict: "Riboti rezervavimą"
        }
    }
}

nonisolated enum SalonCancellationRemedy: String, CaseIterable, Identifiable, Hashable, Codable {
    case refund
    case priorityRebooking
    case loyaltyBonus
    case credit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .refund: "Grąžinti pinigus"
        case .priorityRebooking: "Pirmumas naujam laikui"
        case .loyaltyBonus: "Lojalumo taškai"
        case .credit: "Kreditas"
        }
    }
}

/// One place where money-and-consequence rules live.
///
/// Later these can vary by location, service, price, client segment and lead time;
/// the engine that resolves them will read this shape, not scattered constants.
nonisolated struct PolicySettings: Hashable, Codable {
    var deposit: DepositRule
    var depositAmount: Double?
    var depositPercent: Double?
    var onTimeCancellation: CancellationOutcome
    var lateCancellation: CancellationOutcome
    var lateCancellationFee: Double?
    var noShow: NoShowConsequence
    var noShowFee: Double?
    var salonCancellation: [SalonCancellationRemedy]

    static let standard = PolicySettings(
        deposit: .none,
        depositAmount: nil,
        depositPercent: nil,
        onTimeCancellation: .refund,
        lateCancellation: .retainDeposit,
        lateCancellationFee: nil,
        noShow: .requireApproval,
        noShowFee: nil,
        salonCancellation: [.refund, .priorityRebooking]
    )

    var depositText: String {
        switch deposit {
        case .none: "Be avanso"
        case .fixedAmount: depositAmount.map { $0.asEuro } ?? "Suma nenustatyta"
        case .percentage: depositPercent.map { "\(Int($0))% nuo kainos" } ?? "Dalis nenustatyta"
        case .fullPrepay: "Visa suma iš anksto"
        case .riskBased: "Pagal kliento riziką"
        }
    }
}

/// Rules that decide when and how a time can be taken.
nonisolated struct BookingSettings: Hashable, Codable {
    /// How soon before the start a client may still book.
    var leadTimeMinutes: Int
    /// How far ahead the calendar is open.
    var bookingHorizonDays: Int
    /// Free cancellation window.
    var cancellationWindowHours: Int
    var rescheduleWindowHours: Int
    var autoConfirmsNormalClients: Bool
    var allowsGuestBooking: Bool
    var allowsRecurringBooking: Bool
    var allowsAnySpecialist: Bool
    /// From how many recorded no-shows a client's bookings wait for approval.
    /// The rule lives in `BookingApprovalPolicy`; this is the number it will read
    /// once settings are stored per business instead of per build.
    var approvalNoShowThreshold: Int
    var waitlist: WaitlistSettings
    var afterHours: AfterHoursSettings

    static let standard = BookingSettings(
        leadTimeMinutes: 120,
        bookingHorizonDays: 60,
        cancellationWindowHours: 24,
        rescheduleWindowHours: 12,
        autoConfirmsNormalClients: true,
        allowsGuestBooking: true,
        allowsRecurringBooking: false,
        allowsAnySpecialist: true,
        approvalNoShowThreshold: BookingApprovalPolicy.noShowThreshold,
        waitlist: .standard,
        afterHours: .standard
    )

    var leadTimeText: String {
        leadTimeMinutes >= 60 ? "\(leadTimeMinutes / 60) val. prieš" : "\(leadTimeMinutes) min. prieš"
    }
}

nonisolated struct WaitlistSettings: Hashable, Codable {
    var isEnabled: Bool
    var allowsFlexibleWindows: Bool
    var autoFillsFreedSlots: Bool
    /// Loyal and long-waiting clients first, once the engine exists.
    var prefersLoyalClients: Bool

    static let standard = WaitlistSettings(
        isEnabled: true,
        allowsFlexibleWindows: true,
        autoFillsFreedSlots: false,
        prefersLoyalClients: true
    )
}

/// Times outside regular hours a specialist may open for a premium.
nonisolated struct AfterHoursSettings: Hashable, Codable {
    var isEnabled: Bool
    /// Whether a specialist can open their own after-hours time, or only the owner.
    var staffCanOpenSlots: Bool
    var premiumPercent: Double
    var requiresPrepay: Bool

    static let standard = AfterHoursSettings(
        isEnabled: false,
        staffCanOpenSlots: false,
        premiumPercent: 20,
        requiresPrepay: true
    )
}
