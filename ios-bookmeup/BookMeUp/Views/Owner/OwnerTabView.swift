import SwiftUI

/// The owner environment.
///
/// Five layers, never more: what needs attention now, the people, the clients, the
/// business itself, and everything advanced. Each new capability finds its place
/// inside one of them through `OwnerModule`, so this navigation stays still while the
/// product keeps growing.
struct OwnerTabView: View {
    var body: some View {
        TabView {
            OwnerTodayView()
                .tabItem { Label(OwnerArea.today.title, systemImage: OwnerArea.today.symbolName) }

            OwnerAreaView(area: .team)
                .tabItem { Label(OwnerArea.team.title, systemImage: OwnerArea.team.symbolName) }

            OwnerClientsView()
                .tabItem { Label(OwnerArea.clients.title, systemImage: OwnerArea.clients.symbolName) }

            OwnerAreaView(area: .business)
                .tabItem { Label(OwnerArea.business.title, systemImage: OwnerArea.business.symbolName) }

            OwnerAreaView(area: .more)
                .tabItem { Label(OwnerArea.more.title, systemImage: OwnerArea.more.symbolName) }
        }
        .tint(Palette.forest)
    }
}
