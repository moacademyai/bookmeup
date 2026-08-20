import SwiftUI

/// Capacity of the active location.
///
/// The demo has three chairs because the demo is a barbershop. The model underneath
/// is a generic resource, so the same screen serves treatment rooms, wash stations or
/// a laser device without a single change.
struct OwnerResourcesView: View {
    @Environment(BusinessStore.self) private var business

    private var resources: [BusinessResource] {
        business.resources(at: business.selectedLocationID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                OwnerSection(
                    title: business.selectedLocation?.name ?? "Resursai",
                    accessory: "\(resources.count)"
                ) {
                    if resources.isEmpty {
                        OwnerEmptyState(
                            title: "Resursų nėra",
                            message: "Pridėk kėdę, kabinetą ar įrangą, kad paslaugos galėtų jas rezervuoti.",
                            symbolName: "square.grid.2x2"
                        )
                    } else {
                        SettingsGroup {
                            ForEach(Array(resources.enumerated()), id: \.element.id) { index, resource in
                                HStack(spacing: 12) {
                                    Image(systemName: resource.type.symbolName)
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(Palette.forest)
                                        .frame(width: 34, height: 34)
                                        .background(Palette.eucalyptus.opacity(0.35), in: .rect(cornerRadius: 11))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(resource.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Palette.ink)
                                        Text(resource.typeTitle)
                                            .font(.caption)
                                            .foregroundStyle(Palette.inkSoft)
                                    }
                                    Spacer(minLength: 8)
                                    OwnerStatusBadge(
                                        text: resource.isActive ? "Naudojama" : "Išjungta",
                                        tone: resource.isActive ? .positive : .neutral
                                    )
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .frame(minHeight: 56)
                                if index < resources.count - 1 {
                                    SettingsDivider()
                                }
                            }
                        }
                    }
                }

                OwnerSection(title: "Tipai") {
                    SettingsGroup {
                        ForEach(Array(ResourceType.allCases.enumerated()), id: \.element) { index, type in
                            HStack(spacing: 12) {
                                Image(systemName: type.symbolName)
                                    .font(.footnote)
                                    .foregroundStyle(Palette.inkSoft)
                                    .frame(width: 34, height: 34)
                                Text(type.title)
                                    .font(.subheadline)
                                    .foregroundStyle(Palette.ink)
                                Spacer(minLength: 8)
                                Text("\(resources.filter { $0.type == type }.count)")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(Palette.inkSoft)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(minHeight: 48)
                            if index < ResourceType.allCases.count - 1 {
                                Divider().overlay(Palette.hairline).padding(.leading, 14)
                            }
                        }
                    }
                }

                OwnerSection(title: "Kas toliau") {
                    OwnerEmptyState(
                        title: "Paslauga reikalauja resurso",
                        message: "Kitas žingsnis — leisti paslaugai nurodyti, kokių resursų jai reikia. Tada kalendorius pats žinos, kad dvi procedūros negali dalintis ta pačia vieta.",
                        symbolName: "link"
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle(OwnerModule.resources.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Palette.bone, for: .navigationBar)
    }
}
