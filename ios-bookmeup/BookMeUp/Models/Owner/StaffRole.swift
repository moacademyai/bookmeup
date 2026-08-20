import Foundation

/// Where a role came from. Custom roles are created by the owner and can be renamed;
/// system roles keep their identity so presets stay recognisable across businesses.
nonisolated enum StaffRoleKind: String, CaseIterable, Identifiable, Hashable, Codable {
    case owner
    case manager
    case administrator
    case employee
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .owner: "Savininkas"
        case .manager: "Vadovas"
        case .administrator: "Administratorius"
        case .employee: "Darbuotojas"
        case .custom: "Individuali rolė"
        }
    }

    var detail: String {
        switch self {
        case .owner: "Pilna prieiga prie viso verslo."
        case .manager: "Platus operacinis valdymas be nuosavybės teisių."
        case .administrator: "Registratūra: kalendorius, klientai, kasdienis salonas."
        case .employee: "Savo kalendorius, savo klientai, savo rezultatai."
        case .custom: "Teisės sudėliotos rankiniu būdu."
        }
    }

    var symbolName: String {
        switch self {
        case .owner: "crown"
        case .manager: "person.badge.shield.checkmark"
        case .administrator: "person.text.rectangle"
        case .employee: "person"
        case .custom: "slider.horizontal.3"
        }
    }
}

/// A named set of permissions.
///
/// The name is a label only — authorisation always reads `permissions`. That is what
/// lets an owner rename a role, build a custom one, or take a single permission away
/// from a manager without any screen changing its logic.
nonisolated struct StaffRole: Identifiable, Hashable, Codable {
    let id: UUID
    let kind: StaffRoleKind
    var name: String
    var permissions: Set<Permission>

    init(id: UUID = UUID(), kind: StaffRoleKind, name: String, permissions: Set<Permission>) {
        self.id = id
        self.kind = kind
        self.name = name
        self.permissions = permissions
    }

    /// The owner role always holds everything; taking a permission from it would lock
    /// the business out of its own account.
    var isLocked: Bool { kind == .owner }

    func can(_ permission: Permission) -> Bool {
        permissions.contains(permission)
    }

    var permissionCountText: String {
        "\(permissions.count) iš \(Permission.allCases.count) teisių"
    }
}
