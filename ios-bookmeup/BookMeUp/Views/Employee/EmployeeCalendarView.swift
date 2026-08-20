import SwiftUI

/// The operational heart of the employee environment: one day, one timeline, either
/// for the signed-in specialist or for the whole floor.
///
/// Both scopes render the same `CalendarTimelineColumn` over the same store reads —
/// "Mano" is simply the team view narrowed to one person, never a second calendar
/// implementation.
struct EmployeeCalendarView: View {
    @Environment(BookMeUpStore.self) private var store

    @State private var path = NavigationPath()
    @State private var selectedDate = Date()
    @State private var scope: CalendarScope = .mine
    @State private var showsMonthPicker = false
    @State private var quickCreate: QuickCreateContext?
    @State private var pendingDraft: CalendarDraft?
    @State private var draft: CalendarDraft?
    @State private var headerScrollX: CGFloat = 0
    @State private var conflictMessage: String?
    /// True only while a hold selection is following the finger, so scrolling
    /// steps aside for that one touch.
    @State private var isPickingTime = false

    private let headerHeight: CGFloat = 52
    /// Every specialist gets a column wide enough to read a client's name in.
    /// Below this the row scrolls instead of squeezing.
    private let minimumColumnWidth: CGFloat = 132

    private var team: [TeamMember] { store.team }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                CalendarDayStrip(
                    selectedDate: $selectedDate,
                    onOpenMonthPicker: { showsMonthPicker = true },
                    onToday: {
                        withAnimation(.easeOut(duration: 0.18)) { selectedDate = Date() }
                    }
                )
                scopePicker
                Divider()
                timeline
            }
            .background(CalendarTheme.canvas)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Booking.self) { booking in
                EmployeeBookingDetailView(bookingID: booking.id)
            }
        }
        .tint(CalendarTheme.accent)
        .sheet(isPresented: $showsMonthPicker) { monthPicker }
        .sheet(item: $quickCreate, onDismiss: presentPendingDraft) { context in
            CalendarQuickCreateSheet(
                time: context.time,
                specialistName: context.specialistName,
                isColleague: context.specialistName != store.specialistName
            ) { choice in
                pendingDraft = choice == .appointment
                    ? .appointment(context.time, context.specialistName)
                    : .block(context.time, context.specialistName)
            }
        }
        .sheet(item: $draft) { draft in
            switch draft {
            case .appointment(let time, let specialist):
                CalendarAppointmentSheet(start: time, specialistName: specialist) { booking in
                    selectedDate = booking.start
                }
                .environment(store)
            case .block(let time, let specialist):
                CalendarBlockSheet(start: time, specialistName: specialist) { title, start, minutes in
                    store.addBlock(title: title, start: start, minutes: minutes, specialistName: specialist)
                    selectedDate = start
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let conflictMessage {
                ToastView(message: conflictMessage)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(2.4))
                        withAnimation(.easeOut(duration: 0.25)) { self.conflictMessage = nil }
                    }
            }
        }
        .animation(.easeOut(duration: 0.2), value: conflictMessage)
    }

    // MARK: - Header

    private var scopePicker: some View {
        Picker("Rodinys", selection: $scope) {
            ForEach(CalendarScope.allCases) { option in
                Text(option.shortTitle).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .background(CalendarTheme.canvas)
    }

    private var monthPicker: some View {
        NavigationStack {
            DatePicker(
                "Data",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .environment(\.locale, Locale(identifier: "lt_LT"))
            .padding(.horizontal, 12)
            .navigationTitle("Pasirink dieną")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Atlikta") { showsMonthPicker = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Timeline

    @ViewBuilder
    private var timeline: some View {
        switch scope {
        case .mine:
            myTimeline
        case .team:
            teamTimeline
        }
    }

    private var myTimeline: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 0) {
                CalendarTimeRail()
                CalendarTimelineColumn(
                    day: selectedDate,
                    items: store.calendarItems(forSpecialist: store.specialistName, on: selectedDate),
                    showsNowLine: true,
                    onOpenBooking: { path.append($0) },
                    onCreate: { time in
                        quickCreate = QuickCreateContext(time: time, specialistName: store.specialistName)
                    },
                    onRemoveBlock: { store.removeBlock($0) },
                    onSelectionActive: { isPickingTime = $0 }
                )
            }
            .padding(.trailing, 6)
            .padding(.top, 6)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .scrollDisabled(isPickingTime)
        .background(CalendarTheme.canvas)
    }

    /// Compact specialist header on top, timeline starting right underneath it.
    ///
    /// The header and the grid are split identically: a fixed rail column, then a
    /// scrolling area exactly `gridWidth` wide. Both widths are stated explicitly.
    /// Left to size itself, the horizontal scroll view reports the combined width of
    /// every specialist column as its ideal width, the row is laid out at that width
    /// instead of the viewport, and the whole timeline drifts sideways — which is what
    /// opened the blank strip down the left of the grid.
    private var teamTimeline: some View {
        GeometryReader { proxy in
            let gridWidth = max(proxy.size.width - CalendarLayout.railWidth, 0)
            let columnWidth = max(gridWidth / CGFloat(max(team.count, 1)), minimumColumnWidth)
            let separators = CGFloat(max(team.count - 1, 0))
            let fitsWithoutScrolling = columnWidth * CGFloat(team.count) + separators <= gridWidth + 1

            VStack(spacing: 0) {
                teamHeader(columnWidth: columnWidth, gridWidth: gridWidth)
                Divider()
                ScrollView {
                    HStack(alignment: .top, spacing: 0) {
                        CalendarTimeRail()

                        ScrollView(.horizontal) {
                            HStack(alignment: .top, spacing: 0) {
                                ForEach(Array(team.enumerated()), id: \.element.id) { index, member in
                                    if index > 0 { columnSeparator }
                                    column(for: member)
                                        .frame(width: columnWidth)
                                }
                            }
                        }
                        .frame(width: gridWidth)
                        .scrollIndicators(.hidden)
                        .scrollDisabled(fitsWithoutScrolling || isPickingTime)
                        .onScrollGeometryChange(for: CGFloat.self) { geometry in
                            geometry.contentOffset.x
                        } action: { _, value in
                            headerScrollX = max(value, 0)
                        }
                    }
                    .frame(
                        width: proxy.size.width,
                        height: CalendarLayout.totalHeight,
                        alignment: .leading
                    )
                    .padding(.top, 6)
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
                .scrollDisabled(isPickingTime)
            }
        }
        .background(CalendarTheme.canvas)
    }

    private func column(for member: TeamMember) -> some View {
        CalendarTimelineColumn(
            day: selectedDate,
            items: store.calendarItems(forSpecialist: member.name, on: selectedDate),
            showsNowLine: true,
            isNarrow: true,
            // Helping a colleague is normal salon work: every column can be booked into.
            isCurrentUser: member.isCurrentUser,
            onOpenBooking: { path.append($0) },
            onCreate: { time in
                quickCreate = QuickCreateContext(time: time, specialistName: member.name)
            },
            onRemoveBlock: { store.removeBlock($0) },
            onSelectionActive: { isPickingTime = $0 }
        )
    }

    /// A single hairline. Enough to say "this booking is Adas's, that empty slot is
    /// Roko's" without drawing a table.
    private var columnSeparator: some View {
        Rectangle()
            .fill(CalendarTheme.hairline)
            .frame(width: 1, height: CalendarLayout.totalHeight)
    }

    private func teamHeader(columnWidth: CGFloat, gridWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: CalendarLayout.railWidth, height: headerHeight)
            HStack(spacing: 0) {
                ForEach(Array(team.enumerated()), id: \.element.id) { index, member in
                    if index > 0 {
                        Rectangle()
                            .fill(CalendarTheme.hairline)
                            .frame(width: 1, height: headerHeight - 16)
                    }
                    memberChip(member)
                        .frame(width: columnWidth, height: headerHeight)
                }
                Spacer(minLength: 0)
            }
            .offset(x: -headerScrollX)
            // The same width as the grid's scrolling area, so a chip and its column
            // stay locked together at every scroll position.
            .frame(width: gridWidth, alignment: .leading)
            .clipped()
        }
        .frame(height: headerHeight)
        .background(CalendarTheme.canvas)
    }

    private func memberChip(_ member: TeamMember) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(member.isCurrentUser ? CalendarTheme.accent.opacity(0.16) : CalendarTheme.fill)
                .frame(width: 30, height: 30)
                .overlay {
                    Text(member.initials)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(member.isCurrentUser ? CalendarTheme.accent : CalendarTheme.secondary)
                }
            VStack(alignment: .leading, spacing: 1) {
                Text(member.firstName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(CalendarTheme.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text("\(store.appointmentCount(forSpecialist: member.name, on: selectedDate)) viz.")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(CalendarTheme.tertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, 10)
        .padding(.trailing, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(member.name), \(store.appointmentCount(forSpecialist: member.name, on: selectedDate)) vizitai")
    }

    private func presentPendingDraft() {
        guard let pendingDraft else { return }
        draft = pendingDraft
        self.pendingDraft = nil
    }
}

/// The moment a long press landed on, and whose column it was.
nonisolated struct QuickCreateContext: Identifiable {
    let id = UUID()
    let time: Date
    let specialistName: String
}

/// Which creation sheet to present after the quick-create choice, and for whom.
nonisolated enum CalendarDraft: Identifiable {
    case appointment(Date, String)
    case block(Date, String)

    var id: String {
        switch self {
        case .appointment(let date, let name): "appointment-\(name)-\(date.timeIntervalSince1970)"
        case .block(let date, let name): "block-\(name)-\(date.timeIntervalSince1970)"
        }
    }
}
