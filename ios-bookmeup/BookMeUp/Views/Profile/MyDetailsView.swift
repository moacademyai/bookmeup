import SwiftUI

/// „Mano duomenys“ — the account record behind the client.
///
/// Reads the existing client record rather than keeping its own copy, so what a client
/// sees here is exactly what their specialist has on file. Nothing sensitive beyond
/// contact details is shown, and nothing is duplicated from the preferences screen.
struct MyDetailsView: View {
    @Environment(BookMeUpStore.self) private var store

    private var client: Client? { store.signedInClient }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                identity

                if let client {
                    ProfileRowGroup {
                        detailRow(icon: "person", title: "Vardas", value: client.firstName)
                        if !client.lastName.isEmpty {
                            ProfileRowDivider()
                            detailRow(icon: "person.text.rectangle", title: "Pavardė", value: client.lastName)
                        }
                        if client.hasPhone {
                            ProfileRowDivider()
                            detailRow(icon: "phone", title: "Telefonas", value: PhoneFormat.display(client.phone))
                        }
                        if let email = client.email, !email.isEmpty {
                            ProfileRowDivider()
                            detailRow(icon: "envelope", title: "El. paštas", value: email)
                        }
                        ProfileRowDivider()
                        detailRow(
                            icon: "calendar",
                            title: "BookMeUp narys nuo",
                            value: client.createdAt.dayText
                        )
                    }

                    Text("Šiuos duomenis mato tik Jus aptarnaujantis verslas. Norėdami juos pakeisti, kreipkitės į savo specialistą — paskyros redagavimas atsiras kartu su prisijungimu.")
                        .font(.caption)
                        .foregroundStyle(Palette.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ContentUnavailableView(
                        "Paskyra neprijungta",
                        systemImage: "person.crop.circle.badge.questionmark",
                        description: Text("Prisijungę matysite savo paskyros duomenis.")
                    )
                    .padding(.top, 40)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle("Mano duomenys")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(Palette.bone, for: .navigationBar)
    }

    private var identity: some View {
        HStack(spacing: 14) {
            InitialsAvatar(name: client?.fullName ?? store.clientName, size: 62)
            VStack(alignment: .leading, spacing: 3) {
                Text(client?.fullName ?? store.clientName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Text("Klientė")
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 16)
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(Palette.forest)
                .frame(width: 34, height: 34)
                .background(Palette.eucalyptus.opacity(0.4), in: .rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Palette.ink)
            }
            Spacer(minLength: 4)
        }
        .frame(minHeight: 44)
        .padding(.vertical, 8)
    }
}
