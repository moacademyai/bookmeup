import SwiftUI

/// The owner's command centre.
///
/// Not a decorative dashboard: it answers two questions in order — what needs a
/// decision right now, and how is the day actually going. Every number is derived
/// from real records; anything without a source says so instead of showing a figure.
struct OwnerTodayView: View {
    @Environment(BookMeUpStore.self) private var store
    @Environment(BusinessStore.self) private var business

    @State private var path = NavigationPath()

    private var today: Date { Date() }

    private var snapshot: OwnerTodaySnapshot {
        OwnerMetrics.snapshot(store: store, business: business, on: today)
    }

    private var actions: [ActionRequiredItem] {
        OwnerMetrics.actionRequired(store: store, business: business, on: today)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    snapshotSection
                    actionRequiredSection
                    revenueRecoverySection
                    insightsSection
                    if DevTools.isEnabled {
                        OwnerDeveloperSection()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .background(Palette.bone)
            .scrollIndicators(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .ownerDestinations()
        }
        .tint(Palette.forest)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                BusinessSelector(
                    businessName: business.business.name,
                    locationName: business.selectedLocation?.city ?? "Lokacija nenustatyta",
                    roleName: business.currentRole?.name ?? "Rolė nenustatyta"
                )
                Spacer(minLength: 8)
                LocationSelector(
                    locations: business.locations,
                    selectedID: business.selectedLocationID,
                    onSelect: { business.selectLocation($0) }
                )
            }

            Text(today.weekdayLongText)
                .font(.subheadline)
                .foregroundStyle(Palette.eucalyptus.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .padding(.top, 8)
        .background(Palette.pine, in: .rect(cornerRadius: 26))
        .padding(.top, 8)
    }

    // MARK: - Snapshot

    private var snapshotSection: some View {
        OwnerSection(
            title: "Dienos vaizdas",
            caption: snapshot.hasActivity
                ? nil
                : "Šiandien dar nėra įrašų — skaičiai atsiranda iš realių rezervacijų."
        ) {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    OwnerMetricCard(
                        value: snapshot.revenue.asEuro,
                        caption: "Dienos pajamos",
                        symbolName: "eurosign.circle",
                        tint: Palette.marigold
                    )
                    OwnerMetricCard(
                        value: "\(snapshot.bookings)",
                        caption: "Rezervacijos",
                        symbolName: "calendar"
                    )
                    OwnerMetricCard(
                        value: snapshot.occupancyText,
                        caption: "Užimtumas",
                        symbolName: "gauge.with.dots.needle.33percent",
                        detail: snapshot.staffWorking > 0 ? nil : "Nėra grafiko"
                    )
                }
                HStack(spacing: 10) {
                    OwnerMetricCard(
                        value: "\(snapshot.newClients)/\(snapshot.returningClients)",
                        caption: "Nauji / grįžtantys",
                        symbolName: "person.2"
                    )
                    OwnerMetricCard(
                        value: "\(snapshot.cancellations)",
                        caption: "Atšaukimai",
                        symbolName: "xmark.circle",
                        tint: snapshot.cancellations > 0 ? Palette.terracotta : Palette.eucalyptus
                    )
                    OwnerMetricCard(
                        value: "\(snapshot.noShows)",
                        caption: "Neatvyko",
                        symbolName: "person.fill.xmark",
                        tint: snapshot.noShows > 0 ? Palette.terracotta : Palette.eucalyptus
                    )
                }
                HStack(spacing: 10) {
                    OwnerMetricCard(
                        value: snapshot.staffText,
                        caption: "Dirba šiandien",
                        symbolName: "person.3",
                        detail: workingNames
                    )
                }
            }
        }
    }

    private var workingNames: String? {
        let names = business.staffWorking(on: today).map(\.firstName)
        guard !names.isEmpty else { return nil }
        return names.joined(separator: ", ")
    }

    // MARK: - Action required

    private var actionRequiredSection: some View {
        OwnerSection(title: "Reikia veiksmo", accessory: actions.isEmpty ? nil : "\(actions.count)") {
            if actions.isEmpty {
                OwnerEmptyState(
                    title: "Nieko nelaukia",
                    message: "Nėra nepatvirtintų rezervacijų, neatsakytų prašymų ar grafiko konfliktų.",
                    symbolName: "checkmark.circle"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(actions) { item in
                        Button {
                            open(item)
                        } label: {
                            OwnerActionRequiredCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func open(_ item: ActionRequiredItem) {
        if let bookingID = item.bookingID, let booking = store.booking(with: bookingID) {
            path.append(booking)
            return
        }
        if let route = item.route {
            path.append(route)
        }
    }

    // MARK: - Revenue recovery

    private var revenueRecoverySection: some View {
        OwnerSection(
            title: "Susigrąžintos pajamos",
            caption: "Tuščia kėdė kainuoja. Čia matysi, kiek kiekvienas mechanizmas grąžino."
        ) {
            OwnerEmptyState(
                title: "Dar nematuojama",
                message: "Šie mechanizmai dar neveikia, todėl sumų nerodome — geriau nieko, negu netikras skaičius.",
                symbolName: "arrow.up.right.circle",
                bullets: RevenueRecoverySource.allCases.map { "\($0.title) — \($0.detail)" }
            )
        }
    }

    // MARK: - Insights

    private var insightsSection: some View {
        OwnerSection(title: "Įžvalgos") {
            OwnerEmptyState(
                title: "AI verslo santrauka",
                message: "Kai susikaups pakankamai istorijos, čia atsiras savininko santrauka ir įspėjimai: sezoniškumas, kritę rodikliai, laisvi tarpai, komandos apkrova.",
                symbolName: "sparkles"
            )
        }
    }
}

/// Development-only environment switch, on the owner's own surface.
private struct OwnerDeveloperSection: View {
    var body: some View {
        DeveloperToolsSection(tone: .light)
    }
}
