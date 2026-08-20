import SwiftUI

/// The permission sheet of one role.
///
/// Every switch here changes what the people holding this role can do across the whole
/// product immediately, because there is only one authorisation path. The owner role
/// is read-only on purpose — a business must not be able to lock itself out.
struct OwnerRoleDetailView: View {
    let roleID: UUID

    @Environment(BusinessStore.self) private var business

    private var role: StaffRole? { business.role(with: roleID) }

    private var canEdit: Bool {
        business.can(.managePermissions) && !(role?.isLocked ?? true)
    }

    var body: some View {
        ScrollView {
            if let role {
                VStack(alignment: .leading, spacing: 22) {
                    summary(role)
                    ForEach(PermissionGroup.allCases) { group in
                        permissionSection(group, role: role)
                    }
                    if canEdit {
                        Button {
                            business.resetRoleToPreset(role.id)
                        } label: {
                            Label("Grąžinti numatytas teises", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(QuietButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 28)
            } else {
                OwnerEmptyState(
                    title: "Rolė nerasta",
                    message: "Šis įrašas nebepasiekiamas.",
                    symbolName: "lock.slash"
                )
                .padding(20)
            }
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle(role?.name ?? "Rolė")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.bone, for: .navigationBar)
    }

    private func summary(_ role: StaffRole) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: role.kind.symbolName)
                    .font(.headline)
                    .foregroundStyle(Palette.forest)
                    .frame(width: 44, height: 44)
                    .background(Palette.eucalyptus.opacity(0.35), in: .circle)
                VStack(alignment: .leading, spacing: 3) {
                    Text(role.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Palette.ink)
                    Text(role.permissionCountText)
                        .font(.caption)
                        .foregroundStyle(Palette.inkSoft)
                }
                Spacer(minLength: 0)
            }

            Text(role.kind.detail)
                .font(.footnote)
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            if role.isLocked {
                Text("Savininko rolė visada turi visas teises — kitaip verslas galėtų užrakinti pats save.")
                    .font(.caption)
                    .foregroundStyle(Palette.terracotta)
                    .fixedSize(horizontal: false, vertical: true)
            } else if !business.can(.managePermissions) {
                Text("Peržiūros režimas: teisėms keisti reikia „Valdyti teises“.")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 16)
        .padding(.top, 6)
    }

    private func permissionSection(_ group: PermissionGroup, role: StaffRole) -> some View {
        let permissions = Permission.all(in: group)
        return OwnerSection(
            title: group.title,
            accessory: "\(permissions.filter { role.can($0) }.count)/\(permissions.count)"
        ) {
            SettingsGroup {
                ForEach(Array(permissions.enumerated()), id: \.element) { index, permission in
                    PermissionToggleRow(
                        permission: permission,
                        isOn: role.can(permission),
                        isLocked: !canEdit
                    ) { enabled in
                        business.setPermission(permission, enabled: enabled, for: role.id)
                    }
                    if index < permissions.count - 1 {
                        Divider().overlay(Palette.hairline).padding(.leading, 14)
                    }
                }
            }
        }
    }
}
