import SwiftUI

/// The service catalogue of the business.
///
/// Uses the same `ServiceOffering` the client environment books and the calendar
/// schedules — one catalogue, not an owner-only copy.
struct OwnerServicesView: View {
    @Environment(BusinessStore.self) private var business

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                OwnerSection(title: "Paslaugos", accessory: "\(business.services.count)") {
                    SettingsGroup {
                        ForEach(Array(business.services.enumerated()), id: \.element.id) { index, service in
                            row(service)
                            if index < business.services.count - 1 {
                                SettingsDivider()
                            }
                        }
                    }
                }

                OwnerSection(title: "Kas atlieka") {
                    SettingsGroup {
                        ForEach(Array(business.activeStaff.enumerated()), id: \.element.id) { index, member in
                            HStack(spacing: 12) {
                                InitialsAvatar(name: member.memberName, size: 34)
                                Text(member.memberName)
                                    .font(.subheadline)
                                    .foregroundStyle(Palette.ink)
                                Spacer(minLength: 8)
                                Text("\(business.services(for: member).count) paslaugos")
                                    .font(.caption)
                                    .foregroundStyle(Palette.inkSoft)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(minHeight: 52)
                            if index < business.activeStaff.count - 1 {
                                SettingsDivider()
                            }
                        }
                    }
                }

                OwnerSection(title: "Sudėtingesnės paslaugos") {
                    OwnerEmptyState(
                        title: "Etapai ir priedai",
                        message: "Paslaugos modelis ruošiamas etapams, kad dažymo laukimo metu kėdė ir specialistas galėtų būti planuojami atskirai.",
                        symbolName: "square.stack.3d.up",
                        bullets: [
                            "Pasiruošimas prieš darbą",
                            "Aktyvus darbas",
                            "Laukimas / veikimo laikas",
                            "Užbaigimas",
                            "Tvarkymasis po vizito",
                            "Kombo, paketai ir priedai"
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
        .navigationTitle(OwnerModule.services.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Palette.bone, for: .navigationBar)
    }

    private func row(_ service: ServiceOffering) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "scissors")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.forest)
                .frame(width: 34, height: 34)
                .background(Palette.eucalyptus.opacity(0.35), in: .rect(cornerRadius: 11))

            VStack(alignment: .leading, spacing: 2) {
                Text(service.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Text(service.detail.isEmpty ? service.durationText : "\(service.detail) · \(service.durationText)")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
            }

            Spacer(minLength: 8)

            Text(service.priceText)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 56)
    }
}
