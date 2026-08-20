import Foundation
import Observation

/// The organisation layer: business, locations, resources, people, roles and rules.
///
/// It deliberately holds no bookings, clients or passport records — those stay in
/// `BookMeUpStore`, which every environment already shares. This store answers a
/// different question: how the business is set up and who is allowed to change it.
@Observable
final class BusinessStore {
    private(set) var business: Business
    private(set) var locations: [BusinessLocation]
    private(set) var resources: [BusinessResource]
    private(set) var services: [ServiceOffering]
    private(set) var roles: [StaffRole]
    private(set) var staff: [StaffMembership]
    private(set) var shifts: [WorkShift]
    private(set) var leaveRequests: [LeaveRequest]
    private(set) var messageTemplates: [MessageTemplate]
    private(set) var auditEvents: [AuditEvent]
    private(set) var bookingSettings: BookingSettings
    private(set) var policySettings: PolicySettings
    private(set) var retentionSettings: RetentionSettings
    private(set) var loyaltySettings: LoyaltySettings

    /// The membership acting right now. In production this is resolved from the signed-in
    /// account and its business membership; the development switch only chooses which
    /// environment is displayed, never who someone is.
    private(set) var currentStaffID: UUID
    private(set) var selectedLocationID: UUID

    private let defaults = UserDefaults.standard
    private let rolesKey = "bookmeup.owner.roles.v1"
    private let locationKey = "bookmeup.owner.location.v1"
    private let staffKey = "bookmeup.owner.currentStaff.v1"

    init() {
        business = OwnerSampleData.business
        locations = OwnerSampleData.locations
        resources = OwnerSampleData.resources
        services = OwnerSampleData.serviceCatalogue
        roles = OwnerSampleData.roles
        staff = OwnerSampleData.staff
        shifts = OwnerSampleData.shifts
        leaveRequests = OwnerSampleData.leaveRequests
        messageTemplates = OwnerSampleData.messageTemplates
        auditEvents = OwnerSampleData.auditEvents
        bookingSettings = .standard
        policySettings = .standard
        retentionSettings = .standard
        loyaltySettings = .standard
        currentStaffID = OwnerSampleData.currentStaffID
        selectedLocationID = OwnerSampleData.panevezysID
        restoreRolePermissions()
        restoreSelection()
    }

    // MARK: - Identity and authorisation

    var currentMembership: StaffMembership? {
        staff.first { $0.id == currentStaffID }
    }

    var currentRole: StaffRole? {
        guard let membership = currentMembership else { return nil }
        return role(with: membership.roleID)
    }

    var accessControl: AccessControl {
        AccessControl(role: currentRole)
    }

    /// The one question the whole product asks before showing or doing anything.
    func can(_ permission: Permission) -> Bool {
        accessControl.can(permission)
    }

    /// Modules of one owner layer the current membership may open.
    func modules(in area: OwnerArea) -> [OwnerModule] {
        accessControl.modules(in: area)
    }

    // MARK: - Reads

    var selectedLocation: BusinessLocation? {
        locations.first { $0.id == selectedLocationID }
    }

    var activeStaff: [StaffMembership] {
        staff.filter { $0.status == .active }
    }

    func role(with id: UUID) -> StaffRole? {
        roles.first { $0.id == id }
    }

    func role(for membership: StaffMembership) -> StaffRole? {
        role(with: membership.roleID)
    }

    func staffMember(with id: UUID) -> StaffMembership? {
        staff.first { $0.id == id }
    }

    /// People assigned to a location, in a stable order.
    func staff(at locationID: UUID) -> [StaffMembership] {
        staff
            .filter { $0.locationIDs.contains(locationID) }
            .sorted { $0.memberName.localizedStandardCompare($1.memberName) == .orderedAscending }
    }

    func resources(at locationID: UUID) -> [BusinessResource] {
        resources.filter { $0.locationID == locationID }
    }

    func shifts(for staffID: UUID) -> [WorkShift] {
        shifts.filter { $0.staffID == staffID }.sorted { $0.weekday < $1.weekday }
    }

    func leaveRequests(for staffID: UUID) -> [LeaveRequest] {
        leaveRequests.filter { $0.staffID == staffID }.sorted { $0.start < $1.start }
    }

    var pendingLeaveRequests: [LeaveRequest] {
        leaveRequests.filter { $0.status == .pending }.sorted { $0.start < $1.start }
    }

    /// Who is rostered on this date at the selected location, from their shift pattern
    /// and any approved leave.
    func staffWorking(on date: Date) -> [StaffMembership] {
        let weekday = AppDate.isoWeekday(of: date)
        return staff(at: selectedLocationID).filter { member in
            guard member.status == .active else { return false }
            let hasShift = shifts.contains {
                $0.staffID == member.id && $0.weekday == weekday && $0.isActive
                    && $0.locationID == selectedLocationID
            }
            guard hasShift else { return false }
            let isAway = leaveRequests.contains {
                $0.staffID == member.id && $0.status == .approved
                    && AppDate.startOfDay($0.start) <= date && date <= AppDate.startOfDay($0.end).addingTimeInterval(86_399)
            }
            return !isAway
        }
    }

    func service(with id: UUID) -> ServiceOffering? {
        services.first { $0.id == id }
    }

    func services(for membership: StaffMembership) -> [ServiceOffering] {
        services.filter { membership.serviceIDs.contains($0.id) }
    }

    // MARK: - Mutations

    func selectLocation(_ id: UUID) {
        guard locations.contains(where: { $0.id == id }) else { return }
        selectedLocationID = id
        defaults.set(id.uuidString, forKey: locationKey)
    }

    /// Turns one permission on or off for a role.
    ///
    /// The owner role is left alone on purpose — a business that can revoke its own
    /// ownership permissions can lock itself out of its own account.
    func setPermission(_ permission: Permission, enabled: Bool, for roleID: UUID) {
        guard let index = roles.firstIndex(where: { $0.id == roleID }), !roles[index].isLocked else { return }
        if enabled {
            roles[index].permissions.insert(permission)
        } else {
            roles[index].permissions.remove(permission)
        }
        persistRolePermissions()
    }

    /// Puts a role back to the preset it started from.
    func resetRoleToPreset(_ roleID: UUID) {
        guard let index = roles.firstIndex(where: { $0.id == roleID }), !roles[index].isLocked else { return }
        roles[index].permissions = RolePresets.permissions(for: roles[index].kind)
        persistRolePermissions()
    }

    func setRole(_ roleID: UUID, for staffID: UUID) {
        guard let index = staff.firstIndex(where: { $0.id == staffID }),
              roles.contains(where: { $0.id == roleID }) else { return }
        staff[index].roleID = roleID
    }

    func setStatus(_ status: StaffStatus, for staffID: UUID) {
        guard let index = staff.firstIndex(where: { $0.id == staffID }) else { return }
        staff[index].status = status
    }

    func decideLeave(_ request: LeaveRequest, status: LeaveStatus) {
        guard let index = leaveRequests.firstIndex(where: { $0.id == request.id }) else { return }
        leaveRequests[index].status = status
    }

    /// Development helper: acts as another membership to see the product through their
    /// permissions. Production resolves this from the account, not from a picker.
    func actAs(_ staffID: UUID) {
        guard staff.contains(where: { $0.id == staffID }) else { return }
        currentStaffID = staffID
        defaults.set(staffID.uuidString, forKey: staffKey)
    }

    // MARK: - Persistence

    /// Only the owner's own edits are stored — the demo content is rebuilt each launch.
    private func persistRolePermissions() {
        let overrides = roles.reduce(into: [String: [String]]()) { result, role in
            result[role.id.uuidString] = role.permissions.map(\.rawValue)
        }
        defaults.set(overrides, forKey: rolesKey)
    }

    private func restoreRolePermissions() {
        guard let stored = defaults.dictionary(forKey: rolesKey) as? [String: [String]] else { return }
        for (key, rawPermissions) in stored {
            guard let id = UUID(uuidString: key),
                  let index = roles.firstIndex(where: { $0.id == id }),
                  !roles[index].isLocked else { continue }
            roles[index].permissions = Set(rawPermissions.compactMap { Permission(rawValue: $0) })
        }
    }

    private func restoreSelection() {
        if let raw = defaults.string(forKey: locationKey),
           let id = UUID(uuidString: raw),
           locations.contains(where: { $0.id == id }) {
            selectedLocationID = id
        }
        if let raw = defaults.string(forKey: staffKey),
           let id = UUID(uuidString: raw),
           staff.contains(where: { $0.id == id }) {
            currentStaffID = id
        }
    }
}
