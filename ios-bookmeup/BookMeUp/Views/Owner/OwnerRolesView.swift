import SwiftUI

/// The roles of the business.
///
/// A role is a named set of permissions and nothing more. Everything the product
/// authorises reads that set, which is why an owner can rename a role, build a new one
/// or take a single permission away without any screen being rewritten.
struct OwnerRolesView: View {
    @Environment(BusinessStore.self) private var business

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                OwnerSection(
                    title: "Rolės",
                    caption: "Pavadinimas yra tik etiketė. Sprendžia teisių rinkinys."
                ) {
                    SettingsGroup {
                        ForEach(Array(business.roles.enumerated()), id: \.element.id) { index, role in
                            NavigationLink(value: OwnerRoute.role(role.id)) {
                                OwnerMenuRow(
                                    title: role.name,
                                    subtitle: role.kind.detail,
                                    symbolName: role.kind.symbolName,
                                    badge: role.isLocked ? "Pilna prieiga" : nil,
                                    badgeTone: role.isLocked ? .positive : .neutral,
                                    trailingText: role.isLocked ? nil : "\(role.permissions.count)"
                                )
                            }
                            .buttonStyle(.plain)
                            if index < business.roles.count - 1 {
                                SettingsDivider()
                            }
                        }
                    }
                }

                OwnerSection(title: "Kas kam priskirta") {
                    SettingsGroup {
                        ForEach(Array(business.roles.enumerated()), id: \.element.id) { index, role in
                            let names = business.staff
                                .filter { $0.roleID == role.id }
                                .map(\.firstName)
                            HStack(spacing: 12) {
                                Image(systemName: role.kind.symbolName)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Palette.forest)
                                    .frame(width: 34, height: 34)
                                    .background(Palette.eucalyptus.opacity(0.35), in: .rect(cornerRadius: 11))
                                Text(role.name)
                                    .font(.subheadline)
                                    .foregroundStyle(Palette.ink)
                                Spacer(minLength: 8)
                                Text(names.isEmpty ? "Niekam" : names.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(Palette.inkSoft)
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(minHeight: 52)
                            if index < business.roles.count - 1 {
                                SettingsDivider()
                            }
                        }
                    }
                }

                OwnerSection(title: "Individualios rolės") {
                    OwnerEmptyState(
                        title: "Sava rolė",
                        message: "Sistema jau palaiko roles, kurių nėra sąraše: teisės saugomos kaip rinkinys, o ne kaip pavadinimas. Rolės kūrimo ekranas — kitas žingsnis.",
                        symbolName: "slider.horizontal.3"
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle(OwnerModule.rolesPermissions.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Palette.bone, for: .navigationBar)
    }
}
