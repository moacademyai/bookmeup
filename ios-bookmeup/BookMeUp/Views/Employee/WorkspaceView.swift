import SwiftUI

/// The specialist's personal work screen.
///
/// Answers four questions and nothing else: how today looks, how much it earns, how
/// strong the schedule ahead is, and who is coming. Creating appointments and blocking
/// time belong to the calendar, and the client base has its own tab — neither is
/// duplicated here.
struct WorkspaceView: View {
    @Environment(BookMeUpStore.self) private var store

    @State private var path = NavigationPath()
    @State private var showsUpcoming = false
    /// Grows the headline number with Dynamic Type instead of clipping it.
    @ScaledMetric(relativeTo: .largeTitle) private var revenueSize: CGFloat = 46

    private var today: EmployeeTodayMetrics { store.todayMetrics }
    private var momentum: EmployeeMomentum { store.momentum }
    private var goal: EmployeeWeeklyGoal { store.weeklyGoal }
    private var appointments: [Booking] { store.todayAppointments }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    header
                    revenue
                    EmployeeMomentumRow(momentum: momentum) { showsUpcoming = true }
                    if goal.target > 0 {
                        EmployeeWeeklyGoalRow(goal: goal)
                    }
                    schedule
                    if DevTools.isEnabled {
                        DeveloperToolsSection(tone: .light)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Palette.bone)
            .scrollIndicators(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Booking.self) { booking in
                EmployeeBookingDetailView(bookingID: booking.id)
            }
            .navigationDestination(for: Client.self) { client in
                ClientProfileView(client: client)
            }
        }
        .tint(Palette.forest)
        .sheet(isPresented: $showsUpcoming) {
            UpcomingServicesSheet(
                total: momentum.upcomingAppointments,
                services: store.upcomingServiceBreakdown,
                revenue: momentum.upcomingRevenue
            )
        }
    }

    // MARK: - Header

    /// No greeting. The specialist knows who they are; what they need is the date.
    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Šiandien")
                .font(.title.weight(.semibold))
                .foregroundStyle(Palette.ink)
            Text(Date().weekdayLongText)
                .font(.subheadline)
                .foregroundStyle(Palette.inkSoft)
        }
    }

    // MARK: - Primary metric

    private var revenue: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(today.expectedRevenue.asEuro)
                .font(.system(size: revenueSize, weight: .semibold).monospacedDigit())
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.25), value: today.expectedRevenue)

            Text("Numatomos pajamos šiandien")
                .font(.subheadline)
                .foregroundStyle(Palette.inkSoft)

            // Only when there is enough finished history for the comparison to be true.
            if let comparison = today.comparisonText {
                Text(comparison)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(today.isAboveAverage ? Palette.forest : Palette.inkSoft)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - Schedule

    private var schedule: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("Šiandienos vizitai")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Spacer(minLength: 8)
                if !appointments.isEmpty {
                    Text("\(appointments.count)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Palette.inkSoft)
                }
            }
            .padding(.bottom, 4)

            TodayScheduleList(appointments: appointments) { booking in
                path.append(booking)
            }
        }
    }
}
