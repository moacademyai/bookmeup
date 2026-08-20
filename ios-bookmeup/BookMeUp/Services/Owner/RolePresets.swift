import Foundation

/// The permission sets a business starts with.
///
/// These are defaults, not laws. An owner can take a permission away from a manager
/// or hand one to an administrator, and nothing in the product breaks — every screen
/// asks for the permission it needs, not for a role name.
nonisolated enum RolePresets {
    /// Everything. The owner cannot be locked out of their own business.
    static var owner: Set<Permission> { Set(Permission.allCases) }

    /// Broad day-to-day command of the salon, without the keys to ownership: roles,
    /// permissions, payouts and payroll stay closed unless the owner opens them.
    static var manager: Set<Permission> {
        var permissions = Set(Permission.allCases)
        permissions.subtract([
            .manageRoles,
            .managePermissions,
            .managePayouts,
            .managePayroll,
            .manageBusinessSettings,
            .managePrivacyRequests,
            .exportClientData
        ])
        return permissions
    }

    /// The front desk. Runs the floor: sees every calendar, books and moves clients,
    /// handles the waitlist, approves risky bookings, talks to clients. Does not touch
    /// ownership, money settings, roles or payroll.
    static var administrator: Set<Permission> {
        [
            .viewOwnCalendar, .viewAllCalendars,
            .createOwnBooking, .createBookingForOthers,
            .editOwnBookings, .editOthersBookings, .cancelBookings, .approveRiskBookings,
            .viewOwnClients, .viewAllClients, .viewClientContactDetails, .editClients,
            .viewOwnStatistics,
            .manageWaitlist,
            .manageMessages,
            .manageGiftCards,
            .manageReviews,
            .manageFixIt,
            .viewOwnRevenue
        ]
    }

    /// A specialist's own working world.
    static var employee: Set<Permission> {
        [
            .viewOwnCalendar,
            .createOwnBooking,
            .editOwnBookings,
            .cancelBookings,
            .viewOwnClients,
            .viewClientContactDetails,
            .viewOwnRevenue,
            .viewOwnStatistics
        ]
    }

    static func permissions(for kind: StaffRoleKind) -> Set<Permission> {
        switch kind {
        case .owner: owner
        case .manager: manager
        case .administrator: administrator
        case .employee: employee
        case .custom: []
        }
    }
}
