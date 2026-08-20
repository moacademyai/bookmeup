import SwiftUI

/// Resolves an owner route to its screen.
///
/// Modules that already work on real data get their own view; the rest land on the
/// foundation screen, which states what will live there instead of pretending.
struct OwnerRouteView: View {
    let route: OwnerRoute

    var body: some View {
        switch route {
        case .module(let module):
            moduleView(module)
        case .staff(let id):
            OwnerStaffDetailView(staffID: id)
        case .role(let id):
            OwnerRoleDetailView(roleID: id)
        case .location(let id):
            OwnerLocationDetailView(locationID: id)
        }
    }

    @ViewBuilder
    private func moduleView(_ module: OwnerModule) -> some View {
        switch module {
        case .employees:
            OwnerStaffListView()
        case .rolesPermissions:
            OwnerRolesView()
        case .leave:
            OwnerLeaveView()
        case .locations:
            OwnerLocationsView()
        case .resources:
            OwnerResourcesView()
        case .services:
            OwnerServicesView()
        case .businessProfile:
            OwnerBusinessProfileView()
        case .bookingSettings:
            OwnerBookingSettingsView()
        case .analytics:
            OwnerAnalyticsView()
        case .clientBase:
            ClientsListView(scope: .business)
        default:
            OwnerModulePlaceholderView(module: module)
        }
    }
}

/// The destinations every owner stack shares, so a card on one tab can link into a
/// screen that belongs to another.
struct OwnerDestinations: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: OwnerRoute.self) { OwnerRouteView(route: $0) }
            .navigationDestination(for: Client.self) { ClientProfileView(client: $0) }
            .navigationDestination(for: Booking.self) { EmployeeBookingDetailView(bookingID: $0.id) }
    }
}

extension View {
    func ownerDestinations() -> some View {
        modifier(OwnerDestinations())
    }
}
