import SwiftUI

/// The team of the business.
///
/// The list works for any number of people — the demo happens to have five. Each row
/// shows what the owner needs at a glance: the role that decides their permissions,
/// their career level and whether they are on the floor at all.
struct OwnerStaffListView: View {
    @Environment(BusinessStore.self) private var business

    private var members: [StaffMembership] {
        business.staff(at: business.selectedLocationID)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if members.isEmpty {
                    OwnerEmptyState(
                        title: "Komandos dar nėra",
                        message: "Pridėk pirmą darbuotoją, kad galėtum priskirti rolę, grafiką ir paslaugas.",
                        symbolName: "person.badge.plus"
                    )
                } else {
                    ForEach(members) { member in
                        NavigationLink(value: OwnerRoute.staff(member.id)) {
                            row(member)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle(OwnerModule.employees.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Palette.bone, for: .navigationBar)
    }

    private func row(_ member: StaffMembership) -> some View {
        HStack(spacing: 12) {
            InitialsAvatar(name: member.memberName, size: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(member.memberName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Text("\(member.craft) · \(member.levelTitle)")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
                HStack(spacing: 6) {
                    OwnerStatusBadge(
                        text: business.role(for: member)?.name ?? "Rolė nenustatyta",
                        tone: .positive,
                        symbolName: business.role(for: member)?.kind.symbolName
                    )
                    if member.status != .active {
                        OwnerStatusBadge(text: member.status.title, tone: .warning)
                    }
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.inkSoft.opacity(0.7))
        }
        .cardSurface(padding: 14, cornerRadius: 20)
        .contentShape(Rectangle())
    }
}
