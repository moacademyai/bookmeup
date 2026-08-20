import Foundation

/// The single authorisation gate of the product.
///
/// Screens ask `can(.manageRoles)` — never `role.name == "Savininkas"` and never
/// `member.name == "Kipras"`. That keeps a renamed role, a custom role and a
/// permission an owner revoked all working without a single view being edited.
nonisolated struct AccessControl: Hashable {
    let permissions: Set<Permission>

    static let none = AccessControl(permissions: [])

    init(permissions: Set<Permission>) {
        self.permissions = permissions
    }

    init(role: StaffRole?) {
        permissions = role?.permissions ?? []
    }

    func can(_ permission: Permission) -> Bool {
        permissions.contains(permission)
    }

    /// True when at least one of these is held — used by menus that lead to a screen
    /// with several independent sections.
    func canAny(_ candidates: [Permission]) -> Bool {
        candidates.contains { permissions.contains($0) }
    }

    func canAll(_ candidates: [Permission]) -> Bool {
        candidates.allSatisfy { permissions.contains($0) }
    }

    /// Modules of one owner layer this membership is allowed to open.
    func modules(in area: OwnerArea) -> [OwnerModule] {
        OwnerModule.modules(in: area).filter { can($0.permission) }
    }
}
