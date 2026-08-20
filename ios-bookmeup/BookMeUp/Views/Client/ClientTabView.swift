import SwiftUI

/// Client environment: Asistentas · Aplink mane · Vizitai · Profilis.
///
/// The order is the product argument. The assistant is first and default because the
/// promise of BookMeUp is that you do not have to search; the map is second for the client
/// who would rather look themselves; visits and profile are where you manage what already
/// exists. Four sections, four jobs, no overlap.
///
/// The conversation and the location reference live here rather than inside a screen, so
/// a client can ask the assistant something, wander to the map, and come back to their
/// answers still there. Appearance is applied here too — one place, so no screen has to
/// know the setting exists.
struct ClientTabView: View {
    @Environment(BookMeUpStore.self) private var store

    @State private var conversation = AssistantConversation()
    @State private var location = DiscoveryLocationService()
    @State private var showExperienceOnboarding = false

    @AppStorage(AppearanceSetting.storageKey) private var storedAppearance = AppearanceSetting.system.rawValue

    private var appearance: AppearanceSetting {
        AppearanceSetting(rawValue: storedAppearance) ?? .system
    }

    var body: some View {
        TabView {
            AssistantHomeView()
                .tabItem { Label("Asistentas", systemImage: "sparkles") }

            NearMeView()
                .tabItem { Label("Aplink mane", systemImage: "mappin.and.ellipse") }

            ClientVisitsView()
                .tabItem { Label("Vizitai", systemImage: "calendar") }

            ProfileView()
                .tabItem { Label("Profilis", systemImage: "person") }
        }
        .tint(Palette.forest)
        .environment(conversation)
        .environment(location)
        .preferredColorScheme(appearance.colorScheme)
        .fullScreenCover(isPresented: $showExperienceOnboarding) {
            ClientExperienceOnboardingView()
        }
        .task(id: store.needsExperienceOnboarding) {
            showExperienceOnboarding = store.needsExperienceOnboarding
        }
        // Businesses register an address, not a pin. Resolving them once at launch is
        // what puts them on the map — including the ones added since the last run.
        .task { await store.resolveBusinessLocations() }
    }
}
