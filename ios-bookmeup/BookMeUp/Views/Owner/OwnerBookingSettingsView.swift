import SwiftUI

/// When and how a time can be taken.
///
/// The approval threshold is shown here for a reason: today the rule lives in
/// `BookingApprovalPolicy` as one number for the whole build, and this is the screen
/// that will own it per business. The rule itself never moves into a view.
struct OwnerBookingSettingsView: View {
    @Environment(BusinessStore.self) private var business

    private var settings: BookingSettings { business.bookingSettings }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                OwnerSection(title: "Bendra") {
                    SettingsGroup {
                        infoRow("Rezervuoti galima ne vėliau kaip", value: settings.leadTimeText, symbol: "clock")
                        SettingsDivider()
                        infoRow("Kalendorius atviras", value: "\(settings.bookingHorizonDays) d. į priekį", symbol: "calendar")
                        SettingsDivider()
                        infoRow("Nemokamas atšaukimas", value: "\(settings.cancellationWindowHours) val. prieš", symbol: "arrow.uturn.left")
                        SettingsDivider()
                        infoRow("Perkėlimas", value: "\(settings.rescheduleWindowHours) val. prieš", symbol: "arrow.left.arrow.right")
                        SettingsDivider()
                        stateRow("Automatinis patvirtinimas", isOn: settings.autoConfirmsNormalClients, symbol: "checkmark.seal")
                        SettingsDivider()
                        stateRow("Rezervacija be paskyros", isOn: settings.allowsGuestBooking, symbol: "person.crop.circle.badge.questionmark")
                        SettingsDivider()
                        stateRow("Pasikartojantys vizitai", isOn: settings.allowsRecurringBooking, symbol: "repeat")
                        SettingsDivider()
                        stateRow("Bet kuris specialistas", isOn: settings.allowsAnySpecialist, symbol: "person.2.badge.gearshape")
                    }
                }

                OwnerSection(
                    title: "Rizika ir patvirtinimas",
                    caption: "Įprastas klientas patvirtinamas iš karto. Rankinis patvirtinimas skirtas tik pasikartojantiems neatvykimams."
                ) {
                    SettingsGroup {
                        infoRow(
                            "Neatvykimų riba",
                            value: "\(settings.approvalNoShowThreshold) ir daugiau",
                            symbol: "person.fill.xmark"
                        )
                        SettingsDivider()
                        infoRow(
                            "Nuo tada rezervacija",
                            value: "laukia patvirtinimo",
                            symbol: "hourglass"
                        )
                    }
                }

                OwnerSection(title: "Laukiančiųjų sąrašas") {
                    SettingsGroup {
                        stateRow("Įjungtas", isOn: settings.waitlist.isEnabled, symbol: "person.badge.clock")
                        SettingsDivider()
                        stateRow("Lankstūs laiko langai", isOn: settings.waitlist.allowsFlexibleWindows, symbol: "square.split.1x2")
                        SettingsDivider()
                        stateRow("Automatinis užpildymas", isOn: settings.waitlist.autoFillsFreedSlots, symbol: "wand.and.stars")
                        SettingsDivider()
                        stateRow("Pirmenybė lojaliems", isOn: settings.waitlist.prefersLoyalClients, symbol: "heart")
                    }
                }

                OwnerSection(
                    title: "Po darbo valandų",
                    caption: "BookMeUp kainodaros principas: premium paklausa gali kelti kainą, automatinio pigimo nedarome."
                ) {
                    SettingsGroup {
                        stateRow("Įjungta", isOn: settings.afterHours.isEnabled, symbol: "moon.stars")
                        SettingsDivider()
                        stateRow("Darbuotojas gali atidaryti", isOn: settings.afterHours.staffCanOpenSlots, symbol: "person.badge.key")
                        SettingsDivider()
                        infoRow("Priedas", value: "\(Int(settings.afterHours.premiumPercent))%", symbol: "arrow.up.right")
                        SettingsDivider()
                        stateRow("Būtinas išankstinis mokėjimas", isOn: settings.afterHours.requiresPrepay, symbol: "creditcard")
                    }
                }

                OwnerSection(title: "Redagavimas") {
                    OwnerEmptyState(
                        title: "Kol kas tik peržiūra",
                        message: "Taisyklės jau saugomos verslo lygmenyje ir turi vieną šaltinį. Redagavimo ekranas ir taisyklės pagal lokaciją, paslaugą ar kliento segmentą — kiti žingsniai.",
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
        .navigationTitle(OwnerModule.bookingSettings.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Palette.bone, for: .navigationBar)
    }

    private func infoRow(_ title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            rowIcon(symbol)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Palette.inkSoft)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 52)
    }

    private func stateRow(_ title: String, isOn: Bool, symbol: String) -> some View {
        HStack(spacing: 12) {
            rowIcon(symbol)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Palette.ink)
            Spacer(minLength: 8)
            OwnerStatusBadge(
                text: isOn ? "Įjungta" : "Išjungta",
                tone: isOn ? .positive : .neutral
            )
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
}
