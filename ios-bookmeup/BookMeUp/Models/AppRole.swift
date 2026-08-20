import Foundation

/// The three BookMeUp environments.
///
/// This enum only decides which navigation is displayed during development. In
/// production the environment follows from the signed-in account, its business
/// membership and the permissions of the role that membership holds — never from a
/// hardcoded person.
nonisolated enum AppRole: String, CaseIterable, Identifiable, Codable {
    case client
    case employee
    case owner

    var id: String { rawValue }

    var title: String {
        switch self {
        case .client: return "Klientas"
        case .employee: return "Darbuotojas"
        case .owner: return "Savininkas"
        }
    }

    var symbolName: String {
        switch self {
        case .client: return "person"
        case .employee: return "briefcase"
        case .owner: return "crown"
        }
    }

    /// Roles that have a navigation environment implemented.
    static var availableRoles: [AppRole] { allCases }
}
