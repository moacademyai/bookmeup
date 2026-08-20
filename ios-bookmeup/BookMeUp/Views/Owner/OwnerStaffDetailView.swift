import SwiftUI

/// One person's place in the business.
///
/// The structure is the point: identity, access, where and what they work, time,
/// money and growth each have a home. Changing someone's role here changes what they
/// can do everywhere, because every screen reads permissions from that role.
struct OwnerStaffDetailView: View {
    let staffID: UUID

    @Environment(BusinessStore.self) private var business

    private var member: StaffMembership? { business.staffMember(with: staffID) }

    var body: some View {
        ScrollView {
            if let member {
                VStack(alignment: .leading, spacing: 22) {
                    profileCard(member)
                    accessSection(member)
                    workSection(member)
                    timeSection(member)
                    compensationSection(member)
                    growthSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 28)
            } else {
                OwnerEmptyState(
                    title: "Darbuotojas nerastas",
                    message: "Šis įrašas nebepasiekiamas.",
                    symbolName: "person.slash"
                )
                .padding(20)
            }
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle(member?.firstName ?? "Darbuotojas")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.bone, for: .navigationBar)
    }

    // MARK: - Sections

    private func profileCard(_ member: StaffMembership) -> some View {
        HStack(spacing: 14) {
            InitialsAvatar(name: member.memberName, size: 62)
            VStack(alignment: .leading, spacing: 4) {
                Text(member.memberName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Text("\(member.craft) · \(member.levelTitle)")
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkSoft)
                if member.hasContacts {
                    Text([member.phone, member.email].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Palette.inkSoft)
                }
            }
            Spacer(minLength: 0)
        }
        .cardSurface(padding: 16)
        .padding(.top, 6)
    }

    private func accessSection(_ member: StaffMembership) -> some View {
        OwnerSection(
            title: "Prieiga",
            caption: "Rolė yra vienintelis šaltinis, nusprendžiantis, ką šis žmogus gali daryti."
        ) {
            SettingsGroup {
                rolePicker(member)
                SettingsDivider()
                statusPicker(member)
                if let role = business.role(for: member) {
                    SettingsDivider()
                    NavigationLink(value: OwnerRoute.role(role.id)) {
                        OwnerMenuRow(
                            title: "Rolės teisės",
                            subtitle: role.permissionCountText,
                            symbolName: "lock.shield"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func rolePicker(_ member: StaffMembership) -> some View {
        HStack(spacing: 12) {
            rowIcon("person.badge.key")
            Text("Rolė")
                .font(.subheadline)
                .foregroundStyle(Palette.ink)
            Spacer(minLength: 8)
            if business.can(.manageRoles) {
                Menu {
                    ForEach(business.roles) { role in
                        Button {
                            business.setRole(role.id, for: member.id)
                        } label: {
                            Label(role.name, systemImage: role.id == member.roleID ? "checkmark" : role.kind.symbolName)
                        }
                    }
                } label: {
                    menuValue(business.role(for: member)?.name ?? "Pasirinkti")
                }
            } else {
                Text(business.role(for: member)?.name ?? "—")
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkSoft)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 56)
    }

    private func statusPicker(_ member: StaffMembership) -> some View {
        HStack(spacing: 12) {
            rowIcon("circle.badge.checkmark")
            Text("Statusas")
                .font(.subheadline)
                .foregroundStyle(Palette.ink)
            Spacer(minLength: 8)
            if business.can(.manageTeam) {
                Menu {
                    ForEach(StaffStatus.allCases) { status in
                        Button {
                            business.setStatus(status, for: member.id)
                        } label: {
                            Label(status.title, systemImage: status == member.status ? "checkmark" : "circle")
                        }
                    }
                } label: {
                    menuValue(member.status.title)
                }
            } else {
                Text(member.status.title)
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkSoft)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 56)
    }

    private func workSection(_ member: StaffMembership) -> some View {
        OwnerSection(title: "Darbas") {
            SettingsGroup {
                infoRow(
                    "Lokacijos",
                    value: member.locationIDs
                        .compactMap { id in business.locations.first { $0.id == id }?.name }
                        .joined(separator: ", "),
                    symbol: "mappin.and.ellipse"
                )
                SettingsDivider()
                infoRow(
                    "Paslaugos",
                    value: "\(business.services(for: member).count) iš \(business.services.count)",
                    symbol: "scissors"
                )
                SettingsDivider()
                infoRow(
                    "Vieša anketa",
                    value: member.showsInMarketplace ? "Rodoma" : "Nerodoma",
                    symbol: "storefront"
                )
            }
        }
    }

    private func timeSection(_ member: StaffMembership) -> some View {
        OwnerSection(title: "Laikas") {
            SettingsGroup {
                ForEach(business.shifts(for: member.id)) { shift in
                    HStack(spacing: 12) {
                        rowIcon("calendar")
                        Text(DayHours(weekday: shift.weekday, isOpen: true, opensMinutes: 0, closesMinutes: 0).weekdayTitle)
                            .font(.subheadline)
                            .foregroundStyle(Palette.ink)
                        Spacer(minLength: 8)
                        Text(shift.rangeText)
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Palette.inkSoft)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(minHeight: 52)
                    SettingsDivider()
                }
                NavigationLink(value: OwnerRoute.module(.leave)) {
                    OwnerMenuRow(
                        title: "Atostogos ir nedarbas",
                        subtitle: leaveSubtitle(member),
                        symbolName: "airplane"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func leaveSubtitle(_ member: StaffMembership) -> String {
        let requests = business.leaveRequests(for: member.id)
        guard !requests.isEmpty else { return "Prašymų nėra" }
        let pending = requests.filter { $0.status == .pending }.count
        return pending > 0 ? "\(pending) laukia sprendimo" : "\(requests.count) įrašai"
    }

    private func compensationSection(_ member: StaffMembership) -> some View {
        OwnerSection(title: "Atlygis") {
            if business.can(.managePayroll) {
                SettingsGroup {
                    infoRow("Schema", value: member.compensation.summaryText, symbol: "banknote")
                }
            } else {
                OwnerEmptyState(
                    title: "Nematoma su tavo teisėmis",
                    message: "Atlygio duomenis mato tik tie, kam savininkas suteikė teisę valdyti atlyginimus.",
                    symbolName: "lock"
                )
            }
        }
    }

    private var growthSection: some View {
        OwnerSection(title: "Augimas") {
            OwnerEmptyState(
                title: "Karjera ir rezultatai",
                message: "Čia atsiras augimo balas, karjeros lygis ir standartų laikymasis — visi skaičiuojami iš realių vizitų, grįžtamumo ir mokymų, o ne priskiriami ranka.",
                symbolName: "chart.line.uptrend.xyaxis",
                bullets: OwnerModule.growth.plannedContent
            )
        }
    }

    // MARK: - Rows

    private func infoRow(_ title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            rowIcon(symbol)
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

    private func rowIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Palette.forest)
            .frame(width: 34, height: 34)
            .background(Palette.eucalyptus.opacity(0.35), in: .rect(cornerRadius: 11))
    }

    private func menuValue(_ text: String) -> some View {
        HStack(spacing: 5) {
            Text(text)
                .font(.subheadline.weight(.semibold))
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(Palette.forest)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Palette.eucalyptus.opacity(0.3), in: .capsule)
    }
}
