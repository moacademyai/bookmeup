import SwiftUI

/// „Profilis“ — the account hub.
///
/// Everything about the client lives behind this screen, and almost nothing lives on it.
/// A profile that lists every preference it stores is a settings dump; this one names the
/// six places a client might need and gets out of the way. Details belong to their own
/// screens, where there is room to explain them.
struct ProfileView: View {
    @Environment(BookMeUpStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    account
                    activity
                    settings
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .background(Palette.bone)
            .scrollIndicators(.hidden)
            .navigationTitle("Profilis")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Palette.bone, for: .navigationBar)
        }
        .tint(Palette.forest)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 14) {
            InitialsAvatar(name: name, size: 58)
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                if let contact {
                    Text(contact)
                        .font(.subheadline)
                        .foregroundStyle(Palette.inkSoft)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 16)
        .padding(.top, 8)
    }

    private var name: String {
        store.signedInClient?.fullName ?? store.clientName
    }

    /// The one identifying detail worth showing here. Never the full contact record.
    private var contact: String? {
        guard let client = store.signedInClient else { return nil }
        if client.hasPhone { return PhoneFormat.display(client.phone) }
        return client.email
    }

    // MARK: - Groups

    private var account: some View {
        ProfileRowGroup {
            ProfileRow(title: "Mano duomenys", symbolName: "person.text.rectangle") {
                MyDetailsView()
            }
            ProfileRowDivider()
            ProfileRow(
                title: "Mano pasirinkimai",
                value: preferencesValue,
                symbolName: "hand.wave"
            ) {
                ClientExperienceEditorView()
            }
        }
    }

    private var preferencesValue: String {
        store.signedInExperienceProfile?.hasSharedPreferences == true ? "Užpildyta" : "Neužpildyta"
    }

    private var activity: some View {
        ProfileRowGroup {
            ProfileRow(
                title: "Lojalumo taškai",
                value: "\(store.loyaltyAccount.pointsText) tšk.",
                symbolName: "sparkles"
            ) {
                LoyaltyView()
            }
            ProfileRowDivider()
            ProfileRow(
                title: "Mėgstamiausi",
                value: store.favoriteProviders.isEmpty ? nil : "\(store.favoriteProviders.count)",
                symbolName: "heart"
            ) {
                FavoritesView()
            }
        }
    }

    private var settings: some View {
        ProfileRowGroup {
            ProfileRow(title: "Pranešimai", symbolName: "bell") {
                NotificationsView()
            }
            ProfileRowDivider()
            ProfileRow(title: "Nustatymai", symbolName: "gearshape") {
                SettingsView()
            }
        }
    }
}
