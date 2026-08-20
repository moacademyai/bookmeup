import SwiftUI

/// The business account itself: who it is, where it trades and under which rules.
struct OwnerBusinessProfileView: View {
    @Environment(BusinessStore.self) private var business

    private var profile: Business { business.business }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                OwnerSection(title: "Kontaktai") {
                    SettingsGroup {
                        infoRow("Telefonas", value: PhoneFormat.display(profile.phone), symbol: "phone")
                        SettingsDivider()
                        infoRow("El. paštas", value: profile.email, symbol: "envelope")
                        SettingsDivider()
                        infoRow("Svetainė", value: profile.website, symbol: "globe")
                    }
                }

                OwnerSection(
                    title: "Rinka",
                    caption: "Šalis, valiuta ir kalba nustatomi versle, o ne užkoduoti ekranuose."
                ) {
                    SettingsGroup {
                        infoRow("Šalis", value: profile.countryName, symbol: "flag")
                        SettingsDivider()
                        infoRow("Valiuta", value: profile.currencyCode, symbol: "eurosign.circle")
                        SettingsDivider()
                        infoRow("Kalba", value: profile.defaultLanguage.uppercased(), symbol: "character.bubble")
                        SettingsDivider()
                        infoRow("Laiko juosta", value: profile.timeZoneIdentifier, symbol: "clock")
                    }
                }

                OwnerSection(title: "Rekvizitai") {
                    SettingsGroup {
                        infoRow("Juridinis pavadinimas", value: profile.legalName, symbol: "doc.text")
                        SettingsDivider()
                        infoRow("PVM", value: profile.vatText, symbol: "percent")
                    }
                }

                OwnerSection(title: "Vieša anketa") {
                    OwnerEmptyState(
                        title: "Marketplace profilis",
                        message: "Vieša verslo anketa, nuotraukos, portfolio ir politikos gyvens atskirame Marketplace modulyje ir naudos tuos pačius verslo duomenis.",
                        symbolName: "storefront",
                        bullets: OwnerModule.marketplace.plannedContent
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle(OwnerModule.businessProfile.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Palette.bone, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(profile.name)
                .font(.title2.weight(.bold))
                .foregroundStyle(Palette.ink)
            Text(profile.marketText)
                .font(.footnote)
                .foregroundStyle(Palette.inkSoft)
            if !profile.about.isEmpty {
                Text(profile.about)
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 16)
        .padding(.top, 6)
    }

    private func infoRow(_ title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.forest)
                .frame(width: 34, height: 34)
                .background(Palette.eucalyptus.opacity(0.35), in: .rect(cornerRadius: 11))
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Palette.ink)
            Spacer(minLength: 8)
            Text(value.isEmpty ? "—" : value)
                .font(.subheadline)
                .foregroundStyle(Palette.inkSoft)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 52)
    }
}
