import Foundation

/// Which of the five owner layers a module belongs to.
nonisolated enum OwnerArea: String, CaseIterable, Identifiable, Hashable {
    case today
    case team
    case clients
    case business
    case more

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Šiandien"
        case .team: "Komanda"
        case .clients: "Klientai"
        case .business: "Verslas"
        case .more: "Daugiau"
        }
    }

    var symbolName: String {
        switch self {
        case .today: "sun.max"
        case .team: "person.3"
        case .clients: "person.2"
        case .business: "building.2"
        case .more: "ellipsis.circle"
        }
    }
}

/// How far a module has been built.
nonisolated enum OwnerModuleReadiness: String, Hashable {
    /// Works on real data today.
    case live
    /// The place exists and the data model is in; the screen is still to come.
    case foundation

    var title: String {
        switch self {
        case .live: "Veikia"
        case .foundation: "Ruošiama"
        }
    }
}

/// The owner's information architecture, in one place.
///
/// Every future owner capability is listed here with the layer it belongs to and the
/// permission that opens it. Menus are built from this list, so adding a capability
/// later means adding a case — never rebuilding the navigation.
nonisolated enum OwnerModule: String, CaseIterable, Identifiable, Hashable {
    // Team
    case employees
    case schedules
    case leave
    case rolesPermissions
    case standards
    case growth
    case teamHealth
    case payroll

    // Clients
    case clientBase
    case segments
    case clientRisk
    case fixIt
    case consents

    // Business
    case businessProfile
    case locations
    case operatingHours
    case resources
    case services
    case pricing
    case bookingSettings
    case policies
    case messages
    case retention
    case aiFrontDesk
    case loyalty
    case giftCards
    case memberships
    case inventory
    case suppliers
    case reviews
    case marketing
    case marketplace

    // More
    case analytics
    case revenueRecovery
    case goals
    case payments
    case taxReceipts
    case integrations
    case notifications
    case auditLog
    case privacy
    case localization
    case security
    case aiCopilot

    var id: String { rawValue }

    var area: OwnerArea {
        switch self {
        case .employees, .schedules, .leave, .rolesPermissions, .standards, .growth, .teamHealth, .payroll:
            .team
        case .clientBase, .segments, .clientRisk, .fixIt, .consents:
            .clients
        case .businessProfile, .locations, .operatingHours, .resources, .services, .pricing,
             .bookingSettings, .policies, .messages, .retention, .aiFrontDesk, .loyalty,
             .giftCards, .memberships, .inventory, .suppliers, .reviews, .marketing, .marketplace:
            .business
        case .analytics, .revenueRecovery, .goals, .payments, .taxReceipts, .integrations,
             .notifications, .auditLog, .privacy, .localization, .security, .aiCopilot:
            .more
        }
    }

    var title: String {
        switch self {
        case .employees: "Darbuotojai"
        case .schedules: "Darbo grafikai"
        case .leave: "Atostogos ir nedarbas"
        case .rolesPermissions: "Rolės ir teisės"
        case .standards: "Salono standartai"
        case .growth: "Augimas ir karjera"
        case .teamHealth: "Komandos savijauta"
        case .payroll: "Atlyginimai ir komisiniai"
        case .clientBase: "Klientų bazė"
        case .segments: "Segmentai"
        case .clientRisk: "Rizika ir reputacija"
        case .fixIt: "Fix It ir atsiprašymai"
        case .consents: "Sutikimai"
        case .businessProfile: "Verslo profilis"
        case .locations: "Lokacijos"
        case .operatingHours: "Darbo laikas"
        case .resources: "Resursai ir talpa"
        case .services: "Paslaugos"
        case .pricing: "Kainodara"
        case .bookingSettings: "Rezervavimo taisyklės"
        case .policies: "Avansai ir neatvykimai"
        case .messages: "Žinutės ir automatizacijos"
        case .retention: "Sugrąžinimas ir win-back"
        case .aiFrontDesk: "AI registratūra"
        case .loyalty: "Lojalumas"
        case .giftCards: "Dovanų kortelės"
        case .memberships: "Narystės ir paketai"
        case .inventory: "Atsargos"
        case .suppliers: "Tiekėjai ir užsakymai"
        case .reviews: "Atsiliepimai ir kokybė"
        case .marketing: "Rinkodara"
        case .marketplace: "Marketplace profilis"
        case .analytics: "Analitika"
        case .revenueRecovery: "Susigrąžintos pajamos"
        case .goals: "Tikslai"
        case .payments: "Mokėjimai ir POS"
        case .taxReceipts: "Mokesčiai ir kvitai"
        case .integrations: "Integracijos"
        case .notifications: "Pranešimai"
        case .auditLog: "Veiksmų žurnalas"
        case .privacy: "Privatumas"
        case .localization: "Kalba ir rinka"
        case .security: "Saugumas"
        case .aiCopilot: "AI padėjėjas"
        }
    }

    var subtitle: String {
        switch self {
        case .employees: "Komandos sąrašas, profiliai, statusas"
        case .schedules: "Pasikartojantys grafikai ir išimtys"
        case .leave: "Prašymai, patvirtinimai, paveikti vizitai"
        case .rolesPermissions: "Kas ką gali daryti"
        case .standards: "Taisyklės, mokymai, onboarding"
        case .growth: "Karjeros lygiai ir rezultatai"
        case .teamHealth: "Pulsas ir apkrova"
        case .payroll: "Schemos, arbatpinigiai, periodai"
        case .clientBase: "Visi klientai ir jų istorija"
        case .segments: "Nauji, lojalūs, rizikoje, prarasti"
        case .clientRisk: "Neatvykimai, ribojimai, blokavimas"
        case .fixIt: "Nesklandumų sprendimas"
        case .consents: "Rinkodara, DND, atsisakymai"
        case .businessProfile: "Pavadinimas, kontaktai, rekvizitai"
        case .locations: "Adresai, laikas, komanda"
        case .operatingHours: "Įprastas laikas, šventės, uždarymai"
        case .resources: "Kėdės, kabinetai, įranga"
        case .services: "Kategorijos, trukmė, etapai"
        case .pricing: "Kainos, priedai, paketai"
        case .bookingSettings: "Kada ir kaip galima registruotis"
        case .policies: "Avansai, atšaukimai, neatvykimai"
        case .messages: "Šablonai, kanalai, laikas"
        case .retention: "Grįžimo ciklas ir kvietimai"
        case .aiFrontDesk: "Vienas verslo protas visiems kanalams"
        case .loyalty: "Taškai, lygiai, privalumai"
        case .giftCards: "Kodai, likučiai, galiojimas"
        case .memberships: "Prenumeratos ir paketai"
        case .inventory: "Prekyba ir profesionalios atsargos"
        case .suppliers: "Užsakymai, savikaina, marža"
        case .reviews: "Vieši ir privatūs vertinimai"
        case .marketing: "Kampanijos ir auditorijos"
        case .marketplace: "Vieša anketa ir portfolio"
        case .analytics: "Pajamos, užimtumas, prognozė"
        case .revenueRecovery: "Tuščios kėdės ekonomika"
        case .goals: "Verslo, lokacijos ir darbuotojo"
        case .payments: "Terminalai, kortelės, grąžinimai"
        case .taxReceipts: "PVM, kvitai, apskaita"
        case .integrations: "Būsena ir klaidos"
        case .notifications: "Kas ir kada pasiekia savininką"
        case .auditLog: "Kas ką pakeitė"
        case .privacy: "Duomenų prašymai ir saugojimas"
        case .localization: "Kalbos, valiuta, formatai"
        case .security: "2FA, sesijos, įrenginiai"
        case .aiCopilot: "Klausimai apie savo verslą"
        }
    }

    var symbolName: String {
        switch self {
        case .employees: "person.3"
        case .schedules: "calendar.badge.clock"
        case .leave: "airplane"
        case .rolesPermissions: "lock.shield"
        case .standards: "checklist"
        case .growth: "chart.line.uptrend.xyaxis"
        case .teamHealth: "heart.text.square"
        case .payroll: "banknote"
        case .clientBase: "person.2"
        case .segments: "square.grid.3x2"
        case .clientRisk: "exclamationmark.shield"
        case .fixIt: "bandage"
        case .consents: "hand.raised"
        case .businessProfile: "building.2"
        case .locations: "mappin.and.ellipse"
        case .operatingHours: "clock"
        case .resources: "chair.lounge"
        case .services: "scissors"
        case .pricing: "tag"
        case .bookingSettings: "slider.horizontal.3"
        case .policies: "creditcard.trianglebadge.exclamationmark"
        case .messages: "bubble.left.and.bubble.right"
        case .retention: "arrow.uturn.backward.circle"
        case .aiFrontDesk: "headphones"
        case .loyalty: "star.circle"
        case .giftCards: "gift"
        case .memberships: "person.crop.rectangle.stack"
        case .inventory: "shippingbox"
        case .suppliers: "truck.box"
        case .reviews: "star.bubble"
        case .marketing: "megaphone"
        case .marketplace: "storefront"
        case .analytics: "chart.bar"
        case .revenueRecovery: "arrow.up.right.circle"
        case .goals: "target"
        case .payments: "creditcard"
        case .taxReceipts: "doc.text"
        case .integrations: "puzzlepiece.extension"
        case .notifications: "bell.badge"
        case .auditLog: "list.bullet.rectangle"
        case .privacy: "lock.doc"
        case .localization: "globe"
        case .security: "checkmark.shield"
        case .aiCopilot: "sparkles"
        }
    }

    /// The permission that opens this module. Menus are filtered by it, so a manager
    /// and an administrator see genuinely different owner apps.
    var permission: Permission {
        switch self {
        case .employees: .manageTeam
        case .schedules: .manageSchedules
        case .leave: .manageLeave
        case .rolesPermissions: .manageRoles
        case .standards: .manageTeam
        case .growth: .viewTeamStatistics
        case .teamHealth: .viewTeamStatistics
        case .payroll: .managePayroll
        case .clientBase: .viewAllClients
        case .segments: .viewAllClients
        case .clientRisk: .blockClients
        case .fixIt: .manageFixIt
        case .consents: .managePrivacyRequests
        case .businessProfile: .manageBusinessSettings
        case .locations: .manageLocations
        case .operatingHours: .manageLocations
        case .resources: .manageResources
        case .services: .manageServices
        case .pricing: .managePricing
        case .bookingSettings: .manageBookingSettings
        case .policies: .manageDeposits
        case .messages: .manageMessages
        case .retention: .manageAutomations
        case .aiFrontDesk: .manageAI
        case .loyalty: .manageLoyalty
        case .giftCards: .manageGiftCards
        case .memberships: .manageMemberships
        case .inventory: .manageInventory
        case .suppliers: .manageSuppliers
        case .reviews: .manageReviews
        case .marketing: .sendMassMessages
        case .marketplace: .manageBusinessSettings
        case .analytics: .viewAllRevenue
        case .revenueRecovery: .viewAllRevenue
        case .goals: .viewTeamStatistics
        case .payments: .managePayments
        case .taxReceipts: .managePayments
        case .integrations: .manageBusinessSettings
        case .notifications: .manageBusinessSettings
        case .auditLog: .viewAuditLog
        case .privacy: .managePrivacyRequests
        case .localization: .manageBusinessSettings
        case .security: .manageBusinessSettings
        case .aiCopilot: .manageAI
        }
    }

    var readiness: OwnerModuleReadiness {
        switch self {
        case .employees, .rolesPermissions, .locations, .resources, .services,
             .bookingSettings, .businessProfile, .clientBase, .analytics, .leave:
            .live
        default:
            .foundation
        }
    }

    /// What this module will hold. Shown on modules that are still foundation, so the
    /// owner can see the plan instead of an empty screen with no explanation.
    var plannedContent: [String] {
        switch self {
        case .schedules:
            ["Pasikartojantys darbo grafikai", "Grafiko išimtys ir laisvos dienos",
             "Lokacijos keitimas", "Paveiktų rezervacijų peržiūra prieš patvirtinant"]
        case .standards:
            ["Kliento patirtis, higiena, darbo vieta", "Komunikacija ir apranga",
             "Procedūrų aprašai ir avarinės situacijos", "Onboarding, mokymai, mini testai"]
        case .growth:
            ["Karjeros lygiai ir kriterijai", "Rezultatai: grįžtamumas, rebooking, prekyba",
             "Standartų laikymasis ir mokymų progresas", "Augimo balas iš realių duomenų"]
        case .teamHealth:
            ["Darbuotojo pulsas", "Apkrovos ir pertraukų balansas", "Įspėjimai apie perdegimą"]
        case .payroll:
            ["Komisiniai už paslaugas ir prekes", "Lokacijai specifinės schemos",
             "Arbatpinigiai ir korekcijos", "Periodai ir eksportas"]
        case .segments:
            ClientSegment.allCases.map(\.title)
        case .clientRisk:
            ["Neatvykimų ir vėlyvų atšaukimų istorija", "Rezervavimo apribojimai",
             "Blokavimas ir jo priežastis", "Reputacijos rodiklis"]
        case .fixIt:
            ["Nesklandumo registracija", "Atsakingas vadovas ir terminas",
             "Nuotraukos ir komentarai", "Sprendimo istorija"]
        case .consents:
            ["Rinkodaros sutikimas atskirai nuo operacinių žinučių",
             "Sutikimų versijos ir istorija", "DND ir tylos valandos", "Atsisakymai"]
        case .operatingHours:
            ["Įprastas savaitės laikas", "Specialios dienos ir šventės",
             "Laikinas uždarymas", "Paveiktų rezervacijų peržiūra"]
        case .pricing:
            ["Bazinės kainos ir trukmės", "Kombo, paketai, priedai",
             "Piko ir po darbo valandų priedas", "Kainos pagal lokaciją"]
        case .policies:
            ["Avansas: nėra, suma, dalis, pilnas, pagal riziką",
             "Atšaukimas laiku ir vėlyvas", "Neatvykimo pasekmės",
             "Salono atšaukimas: grąžinimas, pirmumas, kompensacija"]
        case .messages:
            ["Šablonai kiekvienam įvykiui", "SMS, push, el. paštas, programėlė",
             "Laikas, kintamieji, peržiūra", "Tylos valandos ir sutikimai"]
        case .retention:
            ["Individualus kliento grįžimo ciklas", "Priminimas artėjant įprastam laikui",
             "„Mes tavęs pasiilgome“ žinutė", "Stipresnis win-back su savininko pasirinkta paskata",
             "Klausimynas „kodėl nebegrįžtate?“"]
        case .aiFrontDesk:
            ["Telefonas, programėlė, svetainė, kiti kanalai",
             "Tas pats kalendorius, kainos ir taisyklės",
             "Kalbos, tonas, darbo laikas", "Leidžiami veiksmai ir eskalavimas"]
        case .loyalty:
            ["Taškai už paslaugas, prekes, atsiliepimus", "Lygiai ir privalumai",
             "Galiojimas tarp lokacijų", "Rankinės korekcijos su žurnalu"]
        case .giftCards:
            ["Skaitmeninės ir fizinės kortelės", "Unikalus kodas ir QR",
             "Likutis ir galiojimas", "Panaudojimo istorija"]
        case .memberships:
            ["Prenumeratos ciklas", "Įtrauktos paslaugos ir limitai",
             "Pauzė ir nutraukimas", "Išankstiniai paketai"]
        case .inventory:
            ["Prekyba ir profesionalios atsargos atskirai", "Likučiai pagal lokaciją",
             "Mažo likučio riba", "Nurašymai, perkėlimai, papildymai"]
        case .suppliers:
            ["Tiekėjų sąrašas", "Užsakymai ir priėmimas", "Savikaina ir marža", "Atsargų apyvarta"]
        case .reviews:
            ["Vieši atsiliepimai ir verslo atsakymai", "Patvirtintas vizitas",
             "Privatus grįžtamasis ryšys", "Rezultato vertinimas po laiko"]
        case .marketing:
            ["Gimtadieniai ir grįžimo kvietimai", "Segmentų kampanijos",
             "Fill My Gap auditorija", "Kampanijų rezultatai"]
        case .marketplace:
            ["Vieša verslo anketa", "Nuotraukos ir portfolio",
             "Patogumai, kalbos, prieinamumas", "Sutikimai prieš/po nuotraukoms"]
        case .revenueRecovery:
            RevenueRecoverySource.allCases.map(\.title)
        case .goals:
            ["Verslo tikslai", "Lokacijos tikslai", "Darbuotojo tikslai", "Progresas realiu laiku"]
        case .payments:
            ["Mokėjimo tiekėjas ir terminalai", "Kortelė byloje kaip tiekėjo žetonas",
             "Grąžinimai, dalinis grąžinimas, ginčai", "Suderinimas dienos pabaigoje"]
        case .taxReceipts:
            ["PVM pagal rinką", "Skaitmeniniai kvitai ir sąskaitos",
             "Apskaitos integracijos", "Eksportas"]
        case .integrations:
            ["Mokėjimai ir POS", "Apskaita", "Kalendorius ir svetainė",
             "Žinutės ir AI", "Būsena, paskutinis sinchronizavimas, klaidos"]
        case .notifications:
            ["Reikia veiksmo", "Šiandien", "Įžvalgos", "Push, el. paštas, programėlėje"]
        case .auditLog:
            ["Kas, kada, ką pakeitė", "Klientas, darbuotojas, savininkas, AI, sistema",
             "Rezervacijos, mokėjimai, teisės, kainos", "Įrašai neredaguojami"]
        case .privacy:
            ["Duomenų eksporto prašymai", "Ištrynimo prašymai",
             "Sutikimų auditas ir versijos", "Saugojimo terminai"]
        case .localization:
            ["Sąsajos kalba", "Verslo ir kliento kalba", "Valiuta, laiko juosta, formatai",
             "Lokalizuoti šablonai"]
        case .security:
            ["Dviejų veiksnių prisijungimas", "Sesijos ir įrenginiai",
             "Rizikingų veiksmų patvirtinimas", "Masinio eksporto apsauga"]
        case .aiCopilot:
            ["„Kodėl šį mėnesį pajamos mažesnės?“", "„Kur daugiausia tuščių tarpų?“",
             "„Kuris darbuotojas turi daugiausia laisvo laiko?“",
             "Atsakymai tik iš realių verslo duomenų",
             "Rimtus veiksmus AI tik paruošia — patvirtina savininkas"]
        default:
            []
        }
    }

    static func modules(in area: OwnerArea) -> [OwnerModule] {
        allCases.filter { $0.area == area }
    }
}
