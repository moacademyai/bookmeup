import SwiftUI

/// „Mėgstamiausi“ — the places the client saved.
///
/// Favorites live here and nowhere else. Repeating them as a feed on the assistant screen
/// would only turn the first screen into a dashboard; a client looking for a place they
/// already chose knows exactly where to find it.
struct FavoritesView: View {
    @Environment(BookMeUpStore.self) private var store
    @Environment(DiscoveryLocationService.self) private var location

    @State private var bookingFlow: BookingFlow?
    @State private var toast: String?

    private var favorites: [Provider] { store.favoriteProviders }

    var body: some View {
        ScrollView {
            if favorites.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(favorites) { provider in
                        row(provider)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle("Mėgstamiausi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(Palette.bone, for: .navigationBar)
        .sheet(item: $bookingFlow) { flow in
            BookingSheet(flow: flow) { booking in
                toast = "Rezervacija patvirtinta · \(booking.start.relativeDayTimeText)"
            }
            .environment(store)
        }
        .overlay(alignment: .bottom) {
            if let toast {
                ToastView(message: toast)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(2.6))
                        withAnimation(.easeOut(duration: 0.25)) { self.toast = nil }
                    }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: toast)
    }

    private func row(_ provider: Provider) -> some View {
        NavigationLink {
            ProviderDetailView(provider: provider)
        } label: {
            BusinessRowCard(
                provider: provider,
                distanceMetres: ClientPersonalization.distance(to: provider, from: location.distanceReference),
                action: {}
            )
            .allowsHitTesting(false)
        }
        .buttonStyle(ExperienceCardPressStyle())
        .swipeActions(edge: .trailing) {
            Button("Pašalinti", role: .destructive) {
                store.toggleFavorite(provider)
            }
        }
        .contextMenu {
            Button {
                bookingFlow = BookingFlow(provider: provider)
            } label: {
                Label("Registruotis", systemImage: "calendar.badge.plus")
            }
            Button(role: .destructive) {
                store.toggleFavorite(provider)
            } label: {
                Label("Pašalinti iš mėgstamiausių", systemImage: "heart.slash")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart")
                .font(.largeTitle)
                .foregroundStyle(Palette.forest.opacity(0.7))
            Text("Dar neturite mėgstamiausių.")
                .font(.subheadline)
                .foregroundStyle(Palette.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 16)
        .cardSurface(padding: 16)
        .padding(.horizontal, 20)
        .padding(.top, 40)
    }
}
