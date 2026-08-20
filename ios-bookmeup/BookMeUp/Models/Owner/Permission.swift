import Foundation

/// How permissions are grouped in the role editor.
nonisolated enum PermissionGroup: String, CaseIterable, Identifiable, Hashable, Codable {
    case calendar
    case bookings
    case clients
    case statistics
    case finance
    case team
    case catalogue
    case business
    case bookingRules
    case communication
    case commerce
    case inventory
    case quality
    case intelligence
    case governance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calendar: "Kalendorius"
        case .bookings: "Rezervacijos"
        case .clients: "Klientai"
        case .statistics: "Statistika"
        case .finance: "Finansai"
        case .team: "Komanda"
        case .catalogue: "Paslaugos ir kainos"
        case .business: "Verslo nustatymai"
        case .bookingRules: "Rezervavimo taisyklės"
        case .communication: "Komunikacija"
        case .commerce: "Lojalumas ir dovanos"
        case .inventory: "Atsargos"
        case .quality: "Kokybė"
        case .intelligence: "AI"
        case .governance: "Priežiūra ir privatumas"
        }
    }

    var symbolName: String {
        switch self {
        case .calendar: "calendar"
        case .bookings: "checkmark.circle"
        case .clients: "person.2"
        case .statistics: "chart.bar"
        case .finance: "eurosign.circle"
        case .team: "person.3"
        case .catalogue: "scissors"
        case .business: "building.2"
        case .bookingRules: "slider.horizontal.3"
        case .communication: "bubble.left.and.bubble.right"
        case .commerce: "gift"
        case .inventory: "shippingbox"
        case .quality: "star"
        case .intelligence: "sparkles"
        case .governance: "lock.shield"
        }
    }
}

/// Every action the product can authorise.
///
/// This is the whole authorisation vocabulary of BookMeUp. A screen never asks
/// "is this person the owner" — it asks whether the signed-in membership holds the
/// permission the action needs. Role names are only labels for a set of these.
nonisolated enum Permission: String, CaseIterable, Identifiable, Hashable, Codable {
    // Calendar
    case viewOwnCalendar
    case viewAllCalendars

    // Bookings
    case createOwnBooking
    case createBookingForOthers
    case editOwnBookings
    case editOthersBookings
    case cancelBookings
    case approveRiskBookings

    // Clients
    case viewOwnClients
    case viewAllClients
    case viewClientContactDetails
    case editClients
    case blockClients

    // Statistics
    case viewOwnStatistics
    case viewTeamStatistics

    // Finance
    case viewOwnRevenue
    case viewAllRevenue
    case managePayments
    case issueRefunds
    case managePayouts
    case managePayroll

    // Team
    case manageTeam
    case manageSchedules
    case manageLeave
    case manageRoles
    case managePermissions

    // Catalogue
    case manageServices
    case managePricing

    // Business
    case manageBusinessSettings
    case manageLocations
    case manageResources

    // Booking rules
    case manageBookingSettings
    case manageDeposits
    case manageNoShowPolicies
    case manageWaitlist

    // Communication
    case manageMessages
    case manageAutomations
    case sendMassMessages

    // Commerce
    case manageLoyalty
    case manageGiftCards
    case manageMemberships

    // Inventory
    case manageInventory
    case manageSuppliers

    // Quality
    case manageReviews
    case manageFixIt

    // Intelligence
    case manageAI
    case approveAIActions

    // Governance
    case viewAuditLog
    case exportClientData
    case managePrivacyRequests

    var id: String { rawValue }

    var group: PermissionGroup {
        switch self {
        case .viewOwnCalendar, .viewAllCalendars:
            .calendar
        case .createOwnBooking, .createBookingForOthers, .editOwnBookings,
             .editOthersBookings, .cancelBookings, .approveRiskBookings:
            .bookings
        case .viewOwnClients, .viewAllClients, .viewClientContactDetails, .editClients, .blockClients:
            .clients
        case .viewOwnStatistics, .viewTeamStatistics:
            .statistics
        case .viewOwnRevenue, .viewAllRevenue, .managePayments, .issueRefunds,
             .managePayouts, .managePayroll:
            .finance
        case .manageTeam, .manageSchedules, .manageLeave, .manageRoles, .managePermissions:
            .team
        case .manageServices, .managePricing:
            .catalogue
        case .manageBusinessSettings, .manageLocations, .manageResources:
            .business
        case .manageBookingSettings, .manageDeposits, .manageNoShowPolicies, .manageWaitlist:
            .bookingRules
        case .manageMessages, .manageAutomations, .sendMassMessages:
            .communication
        case .manageLoyalty, .manageGiftCards, .manageMemberships:
            .commerce
        case .manageInventory, .manageSuppliers:
            .inventory
        case .manageReviews, .manageFixIt:
            .quality
        case .manageAI, .approveAIActions:
            .intelligence
        case .viewAuditLog, .exportClientData, .managePrivacyRequests:
            .governance
        }
    }

    var title: String {
        switch self {
        case .viewOwnCalendar: "Matyti savo kalendorių"
        case .viewAllCalendars: "Matyti visų kalendorius"
        case .createOwnBooking: "Kurti savo rezervacijas"
        case .createBookingForOthers: "Kurti rezervacijas kitiems"
        case .editOwnBookings: "Redaguoti savo rezervacijas"
        case .editOthersBookings: "Redaguoti kitų rezervacijas"
        case .cancelBookings: "Atšaukti rezervacijas"
        case .approveRiskBookings: "Tvirtinti rizikingas rezervacijas"
        case .viewOwnClients: "Matyti savo klientus"
        case .viewAllClients: "Matyti visus klientus"
        case .viewClientContactDetails: "Matyti klientų kontaktus"
        case .editClients: "Redaguoti klientus"
        case .blockClients: "Riboti ir blokuoti klientus"
        case .viewOwnStatistics: "Matyti savo statistiką"
        case .viewTeamStatistics: "Matyti komandos statistiką"
        case .viewOwnRevenue: "Matyti savo pajamas"
        case .viewAllRevenue: "Matyti visas verslo pajamas"
        case .managePayments: "Valdyti mokėjimus"
        case .issueRefunds: "Grąžinti pinigus"
        case .managePayouts: "Valdyti išmokas"
        case .managePayroll: "Valdyti atlyginimus"
        case .manageTeam: "Valdyti komandą"
        case .manageSchedules: "Valdyti darbo grafikus"
        case .manageLeave: "Tvirtinti atostogas ir nedarbą"
        case .manageRoles: "Valdyti roles"
        case .managePermissions: "Valdyti teises"
        case .manageServices: "Valdyti paslaugas"
        case .managePricing: "Valdyti kainas"
        case .manageBusinessSettings: "Valdyti verslo nustatymus"
        case .manageLocations: "Valdyti lokacijas"
        case .manageResources: "Valdyti resursus"
        case .manageBookingSettings: "Valdyti rezervavimo taisykles"
        case .manageDeposits: "Valdyti avansus"
        case .manageNoShowPolicies: "Valdyti neatvykimo politiką"
        case .manageWaitlist: "Valdyti laukiančiųjų sąrašą"
        case .manageMessages: "Valdyti žinutes"
        case .manageAutomations: "Valdyti automatizacijas"
        case .sendMassMessages: "Siųsti masines žinutes"
        case .manageLoyalty: "Valdyti lojalumą"
        case .manageGiftCards: "Valdyti dovanų korteles"
        case .manageMemberships: "Valdyti narystes"
        case .manageInventory: "Valdyti atsargas"
        case .manageSuppliers: "Valdyti tiekėjus"
        case .manageReviews: "Valdyti atsiliepimus"
        case .manageFixIt: "Valdyti Fix It atvejus"
        case .manageAI: "Valdyti AI nustatymus"
        case .approveAIActions: "Tvirtinti AI veiksmus"
        case .viewAuditLog: "Matyti veiksmų žurnalą"
        case .exportClientData: "Eksportuoti klientų duomenis"
        case .managePrivacyRequests: "Tvarkyti privatumo prašymus"
        }
    }

    /// Permissions an owner should think twice before handing out. The role editor
    /// marks them so the consequence is visible before the switch is flipped.
    var isSensitive: Bool {
        switch self {
        case .manageRoles, .managePermissions, .managePayouts, .managePayroll,
             .manageBusinessSettings, .exportClientData, .managePrivacyRequests,
             .issueRefunds, .viewAllRevenue:
            true
        default:
            false
        }
    }

    static func all(in group: PermissionGroup) -> [Permission] {
        allCases.filter { $0.group == group }
    }
}
