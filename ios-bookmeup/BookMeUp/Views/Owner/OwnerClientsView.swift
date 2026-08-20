import SwiftUI

/// The owner's client layer.
///
/// It reuses the existing client module outright — same records, same search, same
/// create-client form, same profile. What changes is scope: the owner sees the whole
/// business base rather than one specialist's clients, and the modules below lead to
/// the relationship, risk and recovery work that sits on top of it.
struct OwnerClientsView: View {
    @Environment(BusinessStore.self) private var business

    private var modules: [OwnerModule] {
        business.modules(in: .clients).filter { $0 != .clientBase }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if business.can(.viewAllClients) {
                        OwnerSection(title: "Bazė") {
                            SettingsGroup {
                                NavigationLink(value: OwnerRoute.module(.clientBase)) {
                                    OwnerMenuRow(
                                        title: OwnerModule.clientBase.title,
                                        subtitle: OwnerModule.clientBase.subtitle,
                                        symbolName: OwnerModule.clientBase.symbolName
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if !modules.isEmpty {
                        OwnerSection(
                            title: "Santykiai",
                            caption: "Kliento vertė, rizika ir grąžinimas — viskas ant tos pačios kliento kortelės."
                        ) {
                            SettingsGroup {
                                ForEach(Array(modules.enumerated()), id: \.element) { index, module in
                                    OwnerModuleRow(module: module)
                                    if index < modules.count - 1 {
                                        SettingsDivider()
                                    }
                                }
                            }
                        }
                    }

                    OwnerSection(title: "Kliento kortelė") {
                        OwnerEmptyState(
                            title: "Client 360",
                            message: "Kliento kortelė jau turi vizitų istoriją, Grožio pasą ir lankomumą. Toliau ant jos gulasi lojalumas, dovanų kortelės, narystės, ribojimai ir Fix It atvejai.",
                            symbolName: "person.text.rectangle",
                            bullets: [
                                "Vizitų istorija ir Grožio pasas",
                                "Neatvykimai, vėlyvi atšaukimai, reputacija",
                                "Lojalumas, paketai, dovanų kortelės",
                                "Sutikimai ir komunikacijos ribos",
                                "Segmentas ir savas specialistas"
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
            .navigationTitle(OwnerArea.clients.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Palette.bone, for: .navigationBar)
            .ownerDestinations()
        }
        .tint(Palette.forest)
    }
}
