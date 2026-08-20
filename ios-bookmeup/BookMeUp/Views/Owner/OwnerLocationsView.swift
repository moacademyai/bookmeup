import SwiftUI

/// The addresses of the business.
///
/// Multi-location is the default shape, not a later upgrade: a second address adds a
/// row here and nothing else in the product has to learn a new concept.
struct OwnerLocationsView: View {
    @Environment(BusinessStore.self) private var business

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                OwnerSection(title: "Lokacijos", accessory: "\(business.locations.count)") {
                    SettingsGroup {
                        ForEach(Array(business.locations.enumerated()), id: \.element.id) { index, location in
                            NavigationLink(value: OwnerRoute.location(location.id)) {
                                OwnerMenuRow(
                                    title: location.name,
                                    subtitle: "\(location.addressText) · \(location.hours.summaryText)",
                                    symbolName: "mappin.and.ellipse",
                                    badge: location.id == business.selectedLocationID ? "Aktyvi" : nil,
                                    badgeTone: location.id == business.selectedLocationID ? .positive : .neutral
                                )
                            }
                            .buttonStyle(.plain)
                            if index < business.locations.count - 1 {
                                SettingsDivider()
                            }
                        }
                    }
                }

                OwnerSection(title: "Kelios lokacijos") {
                    OwnerEmptyState(
                        title: "Paruošta plėtrai",
                        message: "Darbuotojai, paslaugos, resursai, atsargos ir rezervavimo taisyklės jau saugomi su lokacijos nuoroda, todėl antras adresas nereikalauja duomenų migracijos.",
                        symbolName: "building.2",
                        bullets: [
                            "Sava laiko juosta, valiuta ir kalba",
                            "Savas darbo laikas ir šventės",
                            "Sava komanda ir resursai",
                            "Savos rezervavimo taisyklės"
                        ]
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle(OwnerModule.locations.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Palette.bone, for: .navigationBar)
    }
}
