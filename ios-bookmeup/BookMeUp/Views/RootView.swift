import SwiftUI

/// Role-aware entry point. Each role gets its own navigation; the reservation
/// store is shared, so client and employee keep reading the same data.
///
/// Appearance is chosen per environment. The client and specialist environments are
/// both built from adaptive semantic tokens, so both follow the appearance the person
/// chose. The owner environment is still pinned to the light appearance because its
/// workspace is built from fixed dark surfaces that were never designed against an
/// adaptive canvas.
struct RootView: View {
    @Binding var role: AppRole

    @AppStorage(AppearanceSetting.storageKey) private var storedAppearance = AppearanceSetting.system.rawValue

    private var appearance: AppearanceSetting {
        AppearanceSetting(rawValue: storedAppearance) ?? .system
    }

    var body: some View {
        switch role {
        case .client:
            ClientTabView()
        case .employee:
            EmployeeTabView()
                .preferredColorScheme(appearance.colorScheme)
        case .owner:
            OwnerTabView()
                .preferredColorScheme(.light)
        }
    }
}
