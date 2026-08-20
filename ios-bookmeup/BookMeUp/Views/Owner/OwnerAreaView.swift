import SwiftUI

/// A whole owner layer — Team, Business or More — built from its modules.
///
/// The menu is generated from `OwnerModule` and filtered by the current membership's
/// permissions, which is why a manager and an administrator open the same app and see
/// genuinely different products. Adding a capability means adding a module case.
struct OwnerAreaView: View {
    let area: OwnerArea

    @Environment(BusinessStore.self) private var business

    private var modules: [OwnerModule] { business.modules(in: area) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if modules.isEmpty {
                        OwnerEmptyState(
                            title: "Nėra prieinamų skilčių",
                            message: "Tavo rolė neturi teisių šiai sričiai. Teises keičia savininkas skiltyje Rolės ir teisės.",
                            symbolName: "lock"
                        )
                    } else {
                        ForEach(groups, id: \.title) { group in
                            OwnerSection(title: group.title, caption: group.caption) {
                                SettingsGroup {
                                    ForEach(Array(group.modules.enumerated()), id: \.element) { index, module in
                                        OwnerModuleRow(module: module)
                                        if index < group.modules.count - 1 {
                                            SettingsDivider()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 28)
            }
            .background(Palette.bone)
            .scrollIndicators(.hidden)
            .navigationTitle(area.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Palette.bone, for: .navigationBar)
            .ownerDestinations()
        }
        .tint(Palette.forest)
    }

    // MARK: - Grouping

    private struct ModuleGroup {
        let title: String
        let caption: String?
        let modules: [OwnerModule]
    }

    /// Modules of a layer, grouped so no screen ever becomes one long wall of cards.
    private var groups: [ModuleGroup] {
        switch area {
        case .team:
            build([
                ("Žmonės", "Kas dirba ir ką jie gali daryti.", [.employees, .rolesPermissions]),
                ("Laikas", "Grafikai, laisvos dienos ir nedarbas.", [.schedules, .leave]),
                ("Augimas", "Karjera, standartai ir savijauta.", [.growth, .standards, .teamHealth]),
                ("Atlygis", nil, [.payroll])
            ])
        case .business:
            build([
                ("Verslas", "Profilis, adresai ir talpa.", [.businessProfile, .locations, .operatingHours, .resources]),
                ("Paslaugos", "Ką siūlote ir už kiek.", [.services, .pricing]),
                ("Rezervavimas", "Taisyklės, avansai ir neatvykimai.", [.bookingSettings, .policies]),
                ("Komunikacija", "Ką ir kada išgirsta klientas.", [.messages, .retention, .aiFrontDesk, .marketing]),
                ("Klientų vertė", "Lojalumas, dovanos ir narystės.", [.loyalty, .giftCards, .memberships]),
                ("Atsargos", nil, [.inventory, .suppliers]),
                ("Reputacija", nil, [.reviews, .marketplace])
            ])
        case .more:
            build([
                ("Verslo protas", "Skaičiai ir atsakymai apie savo verslą.", [.analytics, .revenueRecovery, .goals, .aiCopilot]),
                ("Finansai", nil, [.payments, .taxReceipts]),
                ("Sistema", nil, [.integrations, .notifications, .localization]),
                ("Priežiūra", "Kas ką pakeitė ir kaip saugomi duomenys.", [.auditLog, .privacy, .security])
            ])
        case .today, .clients:
            build([("Skiltys", nil, modules)])
        }
    }

    private func build(_ raw: [(String, String?, [OwnerModule])]) -> [ModuleGroup] {
        let allowed = Set(modules)
        return raw.compactMap { title, caption, candidates in
            let visible = candidates.filter { allowed.contains($0) }
            guard !visible.isEmpty else { return nil }
            return ModuleGroup(title: title, caption: caption, modules: visible)
        }
    }
}
