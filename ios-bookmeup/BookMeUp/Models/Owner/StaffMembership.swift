import Foundation

nonisolated enum StaffStatus: String, CaseIterable, Identifiable, Hashable, Codable {
    case active
    case inactive
    case invited

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active: "Dirba"
        case .inactive: "Neaktyvus"
        case .invited: "Pakviestas"
        }
    }
}

/// Career ladder. `custom` lets a business name its own levels without a code change.
nonisolated enum CareerLevel: String, CaseIterable, Identifiable, Hashable, Codable {
    case junior
    case specialist
    case senior
    case master
    case educator
    case manager
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .junior: "Jaunesnysis"
        case .specialist: "Specialistas"
        case .senior: "Vyresnysis"
        case .master: "Meistras"
        case .educator: "Mokytojas"
        case .manager: "Vadovas"
        case .custom: "Individualus lygis"
        }
    }
}

nonisolated enum CompensationKind: String, CaseIterable, Identifiable, Hashable, Codable {
    case fixed
    case servicePercentage
    case mixed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fixed: "Fiksuotas atlygis"
        case .servicePercentage: "Procentas nuo paslaugų"
        case .mixed: "Mišri schema"
        }
    }
}

/// How one person is paid. No engine calculates from this yet — it is the shape
/// payroll and commission will read once payments are real.
nonisolated struct StaffCompensation: Hashable, Codable {
    var kind: CompensationKind
    var servicePercent: Double?
    var retailPercent: Double?

    static let unset = StaffCompensation(kind: .fixed, servicePercent: nil, retailPercent: nil)

    var summaryText: String {
        switch kind {
        case .fixed:
            return "Fiksuotas atlygis"
        case .servicePercentage:
            return servicePercent.map { "Paslaugos \(Int($0))%" } ?? "Procentas nenustatytas"
        case .mixed:
            let service = servicePercent.map { "paslaugos \(Int($0))%" } ?? "paslaugos —"
            let retail = retailPercent.map { "prekės \(Int($0))%" } ?? "prekės —"
            return "Mišri · \(service), \(retail)"
        }
    }
}

/// A person's place inside a business.
///
/// The person on the floor stays `TeamMember` — the calendar column identity is not
/// duplicated here. This record is the membership: which business they belong to,
/// which role they hold, which locations and services they work, how they are paid.
/// Authorisation reads the role this points at, never the person's name.
nonisolated struct StaffMembership: Identifiable, Hashable, Codable {
    let id: UUID
    let businessID: UUID
    /// The same display name the calendar and bookings use, so no second identity
    /// for the same human being.
    var memberName: String
    var craft: String
    var roleID: UUID
    var status: StaffStatus
    var locationIDs: [UUID]
    var serviceIDs: [UUID]
    var phone: String
    var email: String
    var careerLevel: CareerLevel
    var customLevelTitle: String?
    var compensation: StaffCompensation
    var showsInMarketplace: Bool
    var joinedAt: Date

    init(
        id: UUID = UUID(),
        businessID: UUID,
        memberName: String,
        craft: String,
        roleID: UUID,
        status: StaffStatus = .active,
        locationIDs: [UUID] = [],
        serviceIDs: [UUID] = [],
        phone: String = "",
        email: String = "",
        careerLevel: CareerLevel = .specialist,
        customLevelTitle: String? = nil,
        compensation: StaffCompensation = .unset,
        showsInMarketplace: Bool = true,
        joinedAt: Date = Date()
    ) {
        self.id = id
        self.businessID = businessID
        self.memberName = memberName
        self.craft = craft
        self.roleID = roleID
        self.status = status
        self.locationIDs = locationIDs
        self.serviceIDs = serviceIDs
        self.phone = phone
        self.email = email
        self.careerLevel = careerLevel
        self.customLevelTitle = customLevelTitle
        self.compensation = compensation
        self.showsInMarketplace = showsInMarketplace
        self.joinedAt = joinedAt
    }

    var levelTitle: String {
        careerLevel == .custom ? (customLevelTitle ?? CareerLevel.custom.title) : careerLevel.title
    }

    var firstName: String {
        memberName.split(separator: " ").first.map(String.init) ?? memberName
    }

    var initials: String {
        memberName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
            .uppercased()
    }

    var hasContacts: Bool {
        !phone.trimmingCharacters(in: .whitespaces).isEmpty
            || !email.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
