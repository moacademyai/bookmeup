import SwiftUI

/// Business analytics.
///
/// Only what can honestly be counted from the records in the app is counted: today,
/// this month, and the team's share of it. Retention, forecasting and occupancy over
/// time need history this demo does not have, so they are named rather than faked.
struct OwnerAnalyticsView: View {
    @Environment(BookMeUpStore.self) private var store
    @Environment(BusinessStore.self) private var business

    private var todaySnapshot: OwnerTodaySnapshot {
        OwnerMetrics.snapshot(store: store, business: business, on: Date())
    }

    private var monthBookings: [Booking] { store.salonMonthlyBookings }

    private var averageTicket: Double {
        guard !monthBookings.isEmpty else { return 0 }
        return store.salonMonthlyRevenue / Double(monthBookings.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                OwnerSection(title: "Šiandien") {
                    HStack(spacing: 10) {
                        OwnerMetricCard(
                            value: todaySnapshot.revenue.asEuro,
                            caption: "Pajamos",
                            symbolName: "eurosign.circle",
                            tint: Palette.marigold
                        )
                        OwnerMetricCard(
                            value: "\(todaySnapshot.bookings)",
                            caption: "Vizitai",
                            symbolName: "calendar"
                        )
                        OwnerMetricCard(
                            value: todaySnapshot.occupancyText,
                            caption: "Užimtumas",
                            symbolName: "gauge.with.dots.needle.33percent"
                        )
                    }
                }

                OwnerSection(title: "Šis mėnuo") {
                    HStack(spacing: 10) {
                        OwnerMetricCard(
                            value: store.salonMonthlyRevenue.asEuro,
                            caption: "Pajamos",
                            symbolName: "chart.bar",
                            tint: Palette.marigold
                        )
                        OwnerMetricCard(
                            value: "\(monthBookings.count)",
                            caption: "Vizitai",
                            symbolName: "calendar.badge.checkmark"
                        )
                        OwnerMetricCard(
                            value: averageTicket.asEuro,
                            caption: "Vidutinis čekis",
                            symbolName: "receipt"
                        )
                    }
                }

                serviceMixSection
                teamSection

                OwnerSection(
                    title: "Ateina",
                    caption: "Šiems rodikliams reikia ilgesnės istorijos, negu turi ši aplinka."
                ) {
                    OwnerEmptyState(
                        title: "Gilesnė analitika",
                        message: "Skaičiuosime tik iš realių verslo duomenų — jokių demonstracinių kreivių.",
                        symbolName: "chart.xyaxis.line",
                        bullets: [
                            "Grįžtamumas, grįžimo ciklas ir churn",
                            "Naujų ir grįžtančių klientų dinamika",
                            "Užimtumas ir išnaudojimas per laiką",
                            "Prekių priedas prie paslaugos",
                            "Lokacijų palyginimas",
                            "Prognozė ir tikslai"
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
        .navigationTitle(OwnerModule.analytics.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Palette.bone, for: .navigationBar)
    }

    // MARK: - Service mix

    private var serviceMix: [(name: String, count: Int, revenue: Double)] {
        Dictionary(grouping: monthBookings, by: \.serviceName)
            .map { (name: $0.key, count: $0.value.count, revenue: $0.value.reduce(0) { $0 + $1.price }) }
            .sorted { $0.revenue > $1.revenue }
    }

    private var serviceMixSection: some View {
        OwnerSection(title: "Paslaugų pjūvis") {
            if serviceMix.isEmpty {
                OwnerEmptyState(
                    title: "Šį mėnesį vizitų dar nėra",
                    message: "Pjūvis atsiras iš pirmos rezervacijos.",
                    symbolName: "scissors"
                )
            } else {
                SettingsGroup {
                    ForEach(Array(serviceMix.enumerated()), id: \.element.name) { index, item in
                        HStack(spacing: 12) {
                            Text(item.name)
                                .font(.subheadline)
                                .foregroundStyle(Palette.ink)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text("\(item.count)×")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Palette.inkSoft)
                            Text(item.revenue.asEuro)
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(Palette.ink)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(minHeight: 48)
                        if index < serviceMix.count - 1 {
                            Divider().overlay(Palette.hairline).padding(.leading, 14)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Team

    private var teamRevenue: [(name: String, revenue: Double, count: Int)] {
        Dictionary(grouping: monthBookings, by: \.specialistName)
            .map { (name: $0.key, revenue: $0.value.reduce(0) { $0 + $1.price }, count: $0.value.count) }
            .sorted { $0.revenue > $1.revenue }
    }

    private var teamSection: some View {
        OwnerSection(title: "Komanda šį mėnesį") {
            if teamRevenue.isEmpty {
                OwnerEmptyState(
                    title: "Duomenų dar nėra",
                    message: "Komandos pjūvis skaičiuojamas iš įvykusių ir suplanuotų vizitų.",
                    symbolName: "person.3"
                )
            } else {
                SettingsGroup {
                    ForEach(Array(teamRevenue.enumerated()), id: \.element.name) { index, item in
                        HStack(spacing: 12) {
                            InitialsAvatar(name: item.name, size: 34)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.subheadline)
                                    .foregroundStyle(Palette.ink)
                                Text("\(item.count) vizitai")
                                    .font(.caption)
                                    .foregroundStyle(Palette.inkSoft)
                            }
                            Spacer(minLength: 8)
                            Text(item.revenue.asEuro)
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(Palette.ink)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(minHeight: 56)
                        if index < teamRevenue.count - 1 {
                            SettingsDivider()
                        }
                    }
                }
            }
        }
    }
}
