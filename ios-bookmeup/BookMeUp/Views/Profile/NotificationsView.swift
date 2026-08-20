import SwiftUI

/// „Pranešimai“ — what BookMeUp is allowed to send.
///
/// Only preferences the app can actually honour. Marketing consent stands on its own and
/// is never implied by anything else: wanting a reminder about a visit is not permission
/// to be sold to.
struct NotificationsView: View {
    @AppStorage("bookmeup.reminders") private var remindersEnabled = true
    @AppStorage("bookmeup.changeAlerts") private var changeAlerts = true
    @AppStorage("bookmeup.marketing") private var marketingConsent = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ProfileRowGroup {
                    toggleRow(
                        isOn: $remindersEnabled,
                        title: "Priminimai apie vizitus",
                        detail: "Priminsime likus dienai iki vizito",
                        icon: "bell"
                    )
                    ProfileRowDivider()
                    toggleRow(
                        isOn: $changeAlerts,
                        title: "Vizitų pakeitimai",
                        detail: "Kai laikas patvirtinamas, perkeliamas ar atšaukiamas",
                        icon: "calendar.badge.exclamationmark"
                    )
                }

                ProfileRowGroup {
                    toggleRow(
                        isOn: $marketingConsent,
                        title: "Pasiūlymai ir naujienos",
                        detail: "Atskiras sutikimas. Galite atšaukti bet kada",
                        icon: "envelope"
                    )
                }

                Text("Pranešimų siuntimas įsijungs kartu su paskyros prisijungimu. Iki tol šie pasirinkimai išsaugomi Jūsų įrenginyje.")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle("Pranešimai")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(Palette.bone, for: .navigationBar)
    }

    private func toggleRow(
        isOn: Binding<Bool>,
        title: String,
        detail: String,
        icon: String
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.footnote)
                    .foregroundStyle(Palette.forest)
                    .frame(width: 34, height: 34)
                    .background(Palette.eucalyptus.opacity(0.4), in: .rect(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Palette.ink)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Palette.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(Palette.forest)
        .padding(.vertical, 8)
    }
}
