import SwiftUI

/// One address: its market settings, its week, its people and its capacity.
struct OwnerLocationDetailView: View {
    let locationID: UUID

    @Environment(BusinessStore.self) private var business

    private var location: BusinessLocation? {
        business.locations.first { $0.id == locationID }
    }

    var body: some View {
        ScrollView {
            if let location {
                VStack(alignment: .leading, spacing: 22) {
                    header(location)
                    marketSection(location)
                    hoursSection(location)
                    teamSection(location)
                    capacitySection(location)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 28)
            } else {
                OwnerEmptyState(
                    title: "Lokacija nerasta",
                    message: "Šis įrašas nebepasiekiamas.",
                    symbolName: "mappin.slash"
                )
                .padding(20)
            }
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle(location?.city ?? "Lokacija")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.bone, for: .navigationBar)
    }

    private func header(_ location: BusinessLocation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(location.name)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Palette.ink)
            Text(location.addressText)
                .font(.subheadline)
                .foregroundStyle(Palette.inkSoft)

            if location.id != business.selectedLocationID {
                Button {
                    business.selectLocation(location.id)
                } label: {
                    Label("Naudoti kaip aktyvią", systemImage: "checkmark.circle")
                }
                .buttonStyle(QuietButtonStyle())
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 16)
        .padding(.top, 6)
    }

    private func marketSection(_ location: BusinessLocation) -> some View {
        OwnerSection(title: "Rinka") {
            SettingsGroup {
                infoRow("Šalis", value: location.countryCode, symbol: "globe")
                SettingsDivider()
                infoRow("Valiuta", value: location.currencyCode, symbol: "eurosign.circle")
                SettingsDivider()
                infoRow("Kalba", value: location.language.uppercased(), symbol: "character.bubble")
                SettingsDivider()
                infoRow("Laiko juosta", value: location.timeZoneIdentifier, symbol: "clock")
            }
        }
    }

    private func hoursSection(_ location: BusinessLocation) -> some View {
        OwnerSection(title: "Darbo laikas", caption: "Šventės ir laikini uždarymai gulasi ant šios savaitės.") {
            SettingsGroup {
                ForEach(Array(location.hours.days.enumerated()), id: \.element.id) { index, day in
                    HStack(spacing: 12) {
                        Text(day.weekdayTitle)
                            .font(.subheadline)
                            .foregroundStyle(day.isOpen ? Palette.ink : Palette.inkSoft)
                        Spacer(minLength: 8)
                        Text(day.rangeText)
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(day.isOpen ? Palette.inkSoft : Palette.terracotta)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(minHeight: 48)
                    if index < location.hours.days.count - 1 {
                        Divider().overlay(Palette.hairline).padding(.leading, 14)
                    }
                }
            }
        }
    }

    private func teamSection(_ location: BusinessLocation) -> some View {
        let members = business.staff(at: location.id)
        return OwnerSection(title: "Komanda", accessory: "\(members.count)") {
            SettingsGroup {
                ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                    NavigationLink(value: OwnerRoute.staff(member.id)) {
                        OwnerMenuRow(
                            title: member.memberName,
                            subtitle: business.role(for: member)?.name,
                            symbolName: "person"
                        )
                    }
                    .buttonStyle(.plain)
                    if index < members.count - 1 {
                        SettingsDivider()
                    }
                }
            }
        }
    }

    private func capacitySection(_ location: BusinessLocation) -> some View {
        let resources = business.resources(at: location.id)
        return OwnerSection(title: "Talpa", accessory: "\(resources.count)") {
            SettingsGroup {
                ForEach(Array(resources.enumerated()), id: \.element.id) { index, resource in
                    HStack(spacing: 12) {
                        Image(systemName: resource.type.symbolName)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Palette.forest)
                            .frame(width: 34, height: 34)
                            .background(Palette.eucalyptus.opacity(0.35), in: .rect(cornerRadius: 11))
                        Text(resource.name)
                            .font(.subheadline)
                            .foregroundStyle(Palette.ink)
                        Spacer(minLength: 8)
                        Text(resource.typeTitle)
                            .font(.caption)
                            .foregroundStyle(Palette.inkSoft)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(minHeight: 52)
                    if index < resources.count - 1 {
                        SettingsDivider()
                    }
                }
            }
        }
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
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Palette.inkSoft)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 52)
    }
}
