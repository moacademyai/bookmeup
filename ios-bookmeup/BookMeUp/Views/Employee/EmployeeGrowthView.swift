import SwiftUI

/// The specialist's own history: am I improving?
///
/// Deliberately not the Today screen with different numbers. Today looks forward and
/// is operational; this looks back and is reflective. Nothing here shows the schedule,
/// and the only comparison ever made is against this specialist's own past — never
/// against a colleague.
struct EmployeeGrowthView: View {
    @Environment(BookMeUpStore.self) private var store

    @State private var period: GrowthPeriod = .thisMonth
    /// Nil until the first calculation finishes, so no placeholder number is ever
    /// mistaken for a real one.
    @State private var report: EmployeeGrowthReport?
    @State private var isLoading = true
    @ScaledMetric(relativeTo: .largeTitle) private var revenueSize: CGFloat = 42

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    periodPicker

                    if let report, report.hasEnoughData {
                        revenue(report)
                        if report.trend.contains(where: { $0.revenue > 0 }) {
                            RevenueTrendChart(points: report.trend)
                        }
                        metrics(report)
                        services(report)
                        records(report)
                    } else if isLoading {
                        loading
                    } else {
                        empty
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 32)
            }
            .background(Palette.bone)
            .scrollIndicators(.hidden)
            .navigationTitle("Augimas")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Palette.bone, for: .navigationBar)
        }
        .tint(Palette.forest)
        // Growth analytics are computed when this tab is opened and when the period
        // changes — never on every render of every other screen.
        .task(id: period) { await load() }
    }

    private func load() async {
        isLoading = true
        let value = store.growthReport(for: period)
        report = value
        isLoading = false
    }

    // MARK: - Period

    private var periodPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(GrowthPeriod.allCases) { option in
                    Button {
                        guard option != period else { return }
                        period = option
                    } label: {
                        Text(option.shortTitle)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(option == period ? Palette.bone : Palette.ink)
                            .padding(.horizontal, 14)
                            .frame(height: 34)
                            .background(
                                option == period ? Palette.ink : Palette.surface,
                                in: .capsule
                            )
                            .overlay {
                                if option != period {
                                    Capsule().stroke(Palette.hairline, lineWidth: 1)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, 0)
        .animation(.easeOut(duration: 0.18), value: period)
    }

    // MARK: - Primary result

    private func revenue(_ report: EmployeeGrowthReport) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(report.revenue.asEuro)
                .font(.system(size: revenueSize, weight: .semibold).monospacedDigit())
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())

            Text(report.period.title())
                .font(.subheadline)
                .foregroundStyle(Palette.inkSoft)

            if let change = report.revenueChangeText() {
                Text(change)
                    .font(.caption.weight(.medium))
                    .foregroundStyle((report.revenueChange ?? 0) > 0 ? Palette.forest : Palette.inkSoft)
                    .padding(.top, 2)
            }
        }
        .animation(.easeOut(duration: 0.25), value: report.revenue)
    }

    // MARK: - Metrics

    private func metrics(_ report: EmployeeGrowthReport) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(report.metrics.enumerated()), id: \.element.id) { index, metric in
                GrowthMetricRow(metric: metric)
                if index < report.metrics.count - 1 {
                    Divider().overlay(Palette.hairline)
                }
            }
        }
        .cardSurface(padding: 16)
    }

    // MARK: - Services

    @ViewBuilder
    private func services(_ report: EmployeeGrowthReport) -> some View {
        if !report.services.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Paslaugos")

                VStack(spacing: 0) {
                    ForEach(Array(report.services.enumerated()), id: \.element.id) { index, service in
                        HStack(spacing: 12) {
                            Text(service.name)
                                .font(.subheadline)
                                .foregroundStyle(Palette.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Text("\(service.count)")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(Palette.ink)
                        }
                        .padding(.vertical, 12)

                        if index < report.services.count - 1 {
                            Divider().overlay(Palette.hairline)
                        }
                    }
                }
                .cardSurface(padding: 16)
            }
        }
    }

    // MARK: - Records

    @ViewBuilder
    private func records(_ report: EmployeeGrowthReport) -> some View {
        if !report.records.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Asmeniniai rekordai")

                VStack(spacing: 0) {
                    ForEach(Array(report.records.enumerated()), id: \.element.id) { index, record in
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.title)
                                    .font(.subheadline)
                                    .foregroundStyle(Palette.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let detail = record.detail {
                                    Text(detail)
                                        .font(.caption)
                                        .foregroundStyle(Palette.inkSoft)
                                }
                            }
                            Spacer(minLength: 8)
                            Text(record.value)
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(Palette.ink)
                        }
                        .padding(.vertical, 12)

                        if index < report.records.count - 1 {
                            Divider().overlay(Palette.hairline)
                        }
                    }
                }
                .cardSurface(padding: 16)
            }
        }
    }

    // MARK: - States

    /// A quiet placeholder rather than an invented number.
    private var loading: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Palette.hairline)
                .frame(width: 160, height: 40)
            RoundedRectangle(cornerRadius: 6)
                .fill(Palette.hairline)
                .frame(width: 110, height: 14)
        }
        .padding(.top, 8)
        .accessibilityLabel("Skaičiuojama")
    }

    private var empty: some View {
        Text("Dar nėra pakankamai duomenų augimo analizei.")
            .font(.subheadline)
            .foregroundStyle(Palette.inkSoft)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 8)
    }
}
