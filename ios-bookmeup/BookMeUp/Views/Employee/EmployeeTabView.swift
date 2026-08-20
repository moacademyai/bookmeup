import SwiftUI

/// Employee environment: Today, Calendar, Clients, Growth.
struct EmployeeTabView: View {
    var body: some View {
        TabView {
            WorkspaceView()
                .tabItem { Label("Šiandien", systemImage: "sun.max") }

            EmployeeCalendarView()
                .tabItem { Label("Kalendorius", systemImage: "calendar") }

            EmployeeClientsTab()
                .tabItem { Label("Klientai", systemImage: "person.2") }

            EmployeeGrowthView()
                .tabItem { Label("Augimas", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .tint(Palette.forest)
    }
}

/// The client base as a root tab of the employee environment.
private struct EmployeeClientsTab: View {
    var body: some View {
        NavigationStack {
            ClientsListView(hidesTabBar: false, showsLargeTitle: false)
                .navigationDestination(for: Client.self) { client in
                    ClientProfileView(client: client)
                }
                .navigationDestination(for: Booking.self) { booking in
                    EmployeeBookingDetailView(bookingID: booking.id)
                }
        }
        .tint(Palette.forest)
    }
}
