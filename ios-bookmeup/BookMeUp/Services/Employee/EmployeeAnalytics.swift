import Foundation

/// Every employee number in one place, computed from booking records only.
///
/// Nothing here touches SwiftUI, `UserDefaults` or the store: it takes appointments,
/// personal blocks and a working schedule, and returns finished values. That is what
/// lets these calculations move to a backend later without a single view changing —
/// and what keeps a screen from quietly inventing a metric of its own.
nonisolated enum EmployeeAnalytics {

    /// Occupancy at which a day counts as effectively full. A day is rarely sold to
    /// the last minute — gaps between appointments are real work time.
    static let fullDayThreshold: Double = 0.8

    /// Days of finished history needed before "your daily average" means anything.
    private static let minimumDaysForAverage = 5

    // MARK: - Revenue rules

    /// Appointments that have actually earned money.
    ///
    /// A cancelled appointment never counts. A confirmed one that has already happened
    /// does, because the visit took place whether or not anyone pressed "finish" —
    /// no-shows are tracked separately and deliberately left out.
    static func isEarned(_ booking: Booking, now: Date = Date()) -> Bool {
        switch booking.status {
        case .completed: true
        case .confirmed: booking.end <= now
        case .pending, .cancelled: false
        }
    }

    /// Appointments still ahead that are expected to earn.
    static func isExpected(_ booking: Booking, now: Date = Date()) -> Bool {
        booking.status.isActive && booking.end > now
    }

    /// Everything that occupies a slot today, earned or still to come.
    static func occupiesTime(_ booking: Booking) -> Bool {
        booking.status != .cancelled
    }

    // MARK: - Day load

    /// One day's load. Personal blocks come out of the sellable time rather than
    /// counting as sold, so a training afternoon does not look like an empty day.
    static func load(
        on date: Date,
        bookings: [Booking],
        blocks: [TimeBlock],
        hours: [OpeningHours]
    ) -> DayLoad {
        let openMinutes: Int = {
            guard let entry = hours.entry(for: date),
                  let opens = entry.opensMinute,
                  let closes = entry.closesMinute else { return 0 }
            return max(closes - opens, 0)
        }()

        let dayBookings = bookings.filter { AppDate.isSameDay($0.start, date) && occupiesTime($0) }
        let dayBlocks = blocks.filter { AppDate.isSameDay($0.start, date) }

        return DayLoad(
            date: AppDate.startOfDay(date),
            openMinutes: openMinutes,
            blockedMinutes: dayBlocks.reduce(0) { $0 + $1.durationMinutes },
            bookedMinutes: dayBookings.reduce(0) { $0 + $1.durationMinutes },
            appointments: dayBookings.count,
            revenue: dayBookings.reduce(0) { $0 + $1.price }
        )
    }

    // MARK: - Today

    static func today(
        bookings: [Booking],
        hours: [OpeningHours],
        now: Date = Date()
    ) -> EmployeeTodayMetrics {
        let todays = bookings.filter { AppDate.isSameDay($0.start, now) && occupiesTime($0) }

        return EmployeeTodayMetrics(
            expectedRevenue: todays.reduce(0) { $0 + $1.price },
            appointments: todays.count,
            dailyAverage: dailyAverage(bookings: bookings, now: now)
        )
    }

    /// Mean revenue of a day that was actually worked.
    ///
    /// Days off and empty days are excluded — comparing today against a average that
    /// includes Sundays would make an ordinary day look extraordinary.
    private static func dailyAverage(bookings: [Booking], now: Date) -> Double? {
        var revenueByDay: [Date: Double] = [:]
        for booking in bookings where isEarned(booking, now: now) && !AppDate.isSameDay(booking.start, now) {
            revenueByDay[AppDate.startOfDay(booking.start), default: 0] += booking.price
        }
        guard revenueByDay.count >= minimumDaysForAverage else { return nil }
        let total = revenueByDay.values.reduce(0, +)
        return total / Double(revenueByDay.count)
    }

    // MARK: - Momentum

    /// How strong the schedule ahead is. The horizon keeps the calculation bounded —
    /// a booking eight months out says nothing about current momentum.
    static func momentum(
        bookings: [Booking],
        blocks: [TimeBlock],
        hours: [OpeningHours],
        now: Date = Date(),
        horizonDays: Int = 60
    ) -> EmployeeMomentum {
        let horizon = AppDate.calendar.date(byAdding: .day, value: horizonDays, to: now) ?? now
        let ahead = bookings.filter { $0.start <= horizon && $0.end > now }
        let upcoming = ahead.filter { isExpected($0, now: now) }

        let weekDays = (0..<7).compactMap { AppDate.calendar.date(byAdding: .day, value: $0, to: now) }
        let weekLoads = weekDays.map { load(on: $0, bookings: bookings, blocks: blocks, hours: hours) }
        let sellable = weekLoads.reduce(0) { $0 + $1.sellableMinutes }
        let booked = weekLoads.reduce(0) { $0 + $1.bookedMinutes }

        let futureDays = (0..<horizonDays).compactMap {
            AppDate.calendar.date(byAdding: .day, value: $0, to: now)
        }
        let strongDays = futureDays
            .map { load(on: $0, bookings: bookings, blocks: blocks, hours: hours) }
            .filter { $0.isWorkingDay && $0.occupancy >= fullDayThreshold }
            .count

        return EmployeeMomentum(
            upcomingAppointments: upcoming.count,
            weekOccupancy: sellable > 0 ? min(Double(booked) / Double(sellable), 1) : 0,
            strongDaysAhead: strongDays,
            cancelledAhead: ahead.filter { $0.status == .cancelled }.count,
            upcomingRevenue: upcoming.reduce(0) { $0 + $1.price }
        )
    }

    /// What kind of work is booked ahead, most frequent first.
    static func upcomingServices(bookings: [Booking], now: Date = Date()) -> [ServiceCount] {
        breakdown(of: bookings.filter { isExpected($0, now: now) })
    }

    private static func breakdown(of bookings: [Booking]) -> [ServiceCount] {
        var counts: [String: (count: Int, revenue: Double)] = [:]
        for booking in bookings {
            let existing = counts[booking.serviceName] ?? (0, 0)
            counts[booking.serviceName] = (existing.count + 1, existing.revenue + booking.price)
        }
        return counts
            .map { ServiceCount(name: $0.key, count: $0.value.count, revenue: $0.value.revenue) }
            .sorted { $0.count == $1.count ? $0.revenue > $1.revenue : $0.count > $1.count }
    }

    // MARK: - Weekly goal

    /// This week's earnings against a target.
    ///
    /// The default target is the specialist's own recent weekly average rounded up, so
    /// the goal is always a real, reachable number they have already beaten before —
    /// not a figure invented by the app. A stored target overrides it.
    static func weeklyGoal(
        bookings: [Booking],
        now: Date = Date(),
        storedTarget: Double? = nil
    ) -> EmployeeWeeklyGoal {
        let weekStart = CalendarLayout.weekStart(for: now)
        let earned = bookings
            .filter { $0.start >= weekStart && isEarned($0, now: now) }
            .reduce(0) { $0 + $1.price }

        if let storedTarget, storedTarget > 0 {
            return EmployeeWeeklyGoal(earned: earned, target: storedTarget, isDerived: false)
        }
        return EmployeeWeeklyGoal(
            earned: earned,
            target: derivedWeeklyTarget(bookings: bookings, weekStart: weekStart, now: now),
            isDerived: true
        )
    }

    private static func derivedWeeklyTarget(bookings: [Booking], weekStart: Date, now: Date) -> Double {
        var revenueByWeek: [Date: Double] = [:]
        for booking in bookings where isEarned(booking, now: now) && booking.start < weekStart {
            revenueByWeek[CalendarLayout.weekStart(for: booking.start), default: 0] += booking.price
        }
        let recent = revenueByWeek
            .sorted { $0.key > $1.key }
            .prefix(8)
            .map(\.value)
        guard !recent.isEmpty else { return 0 }
        let average = recent.reduce(0, +) / Double(recent.count)
        // Rounded to a number a person would actually say out loud.
        return max((average / 50).rounded(.up) * 50, 50)
    }

    // MARK: - Growth

    /// One pass over history for the whole Growth tab.
    static func growth(
        period: GrowthPeriod,
        bookings: [Booking],
        blocks: [TimeBlock],
        hours: [OpeningHours],
        attendance: [ClientAttendanceEvent],
        now: Date = Date()
    ) -> EmployeeGrowthReport {
        let range = period.range(now: now)
        let previous = period.previousRange(now: now)

        let earned = bookings.filter { isEarned($0, now: now) }
        let current = earned.filter { range.contains($0.start) }
        let before = earned.filter { previous.contains($0.start) }

        guard !current.isEmpty || !before.isEmpty else {
            return .empty(period)
        }

        let revenue = current.reduce(0) { $0 + $1.price }
        let previousRevenue = before.reduce(0) { $0 + $1.price }

        let occupancy = occupancyRate(in: range, bookings: bookings, blocks: blocks, hours: hours, now: now)
        let previousOccupancy = occupancyRate(in: previous, bookings: bookings, blocks: blocks, hours: hours, now: now)

        let clients = clientSplit(current: current, allEarned: earned, range: range)
        let previousClients = clientSplit(current: before, allEarned: earned, range: previous)

        let cancellations = bookings.filter { $0.status == .cancelled && range.contains($0.start) }.count
        let previousCancellations = bookings.filter { $0.status == .cancelled && previous.contains($0.start) }.count
        let noShows = attendance.filter { $0.kind == .noShow && range.contains($0.date) }.count
        let previousNoShows = attendance.filter { $0.kind == .noShow && previous.contains($0.date) }.count

        let workedDays = Set(current.map { AppDate.startOfDay($0.start) }).count

        var metrics: [GrowthMetric] = [
            GrowthMetric(
                key: "visits",
                title: "Vizitai",
                value: "\(current.count)",
                current: Double(current.count),
                previous: Double(before.count),
                direction: .higherIsBetter
            ),
            GrowthMetric(
                key: "check",
                title: "Vidutinis čekis",
                value: current.isEmpty ? "—" : (revenue / Double(current.count)).asEuro,
                current: current.isEmpty ? 0 : revenue / Double(current.count),
                previous: before.isEmpty ? nil : previousRevenue / Double(before.count),
                direction: .higherIsBetter
            ),
            GrowthMetric(
                key: "occupancy",
                title: "Užimtumas",
                value: "\(Int((occupancy * 100).rounded())) %",
                current: occupancy,
                previous: previousOccupancy > 0 ? previousOccupancy : nil,
                direction: .higherIsBetter
            ),
            GrowthMetric(
                key: "returning",
                title: "Grįžtantys klientai",
                value: "\(clients.returning)",
                current: Double(clients.returning),
                previous: Double(previousClients.returning),
                direction: .higherIsBetter
            ),
            GrowthMetric(
                key: "new",
                title: "Nauji klientai",
                value: "\(clients.new)",
                current: Double(clients.new),
                previous: Double(previousClients.new),
                direction: .higherIsBetter
            ),
            GrowthMetric(
                key: "returnRate",
                title: "Sugrįžimo rodiklis",
                value: clients.total > 0 ? "\(Int((clients.returnRate * 100).rounded())) %" : "—",
                current: clients.returnRate,
                previous: previousClients.total > 0 ? previousClients.returnRate : nil,
                direction: .higherIsBetter
            ),
            GrowthMetric(
                key: "perDay",
                title: "Vid. klientų per dieną",
                value: workedDays > 0 ? NumberText.oneDecimal(Double(current.count) / Double(workedDays)) : "—",
                current: workedDays > 0 ? Double(current.count) / Double(workedDays) : 0,
                previous: nil,
                direction: .higherIsBetter
            ),
            GrowthMetric(
                key: "revenuePerDay",
                title: "Vid. pajamos per dieną",
                value: workedDays > 0 ? (revenue / Double(workedDays)).asEuro : "—",
                current: workedDays > 0 ? revenue / Double(workedDays) : 0,
                previous: nil,
                direction: .higherIsBetter
            ),
            GrowthMetric(
                key: "cancellations",
                title: "Atšaukimai",
                value: "\(cancellations)",
                current: Double(cancellations),
                previous: Double(previousCancellations),
                direction: .lowerIsBetter
            )
        ]

        // Only ever shown when the salon actually records no-shows.
        if noShows > 0 || previousNoShows > 0 {
            metrics.append(
                GrowthMetric(
                    key: "noShow",
                    title: "Neatvykimai",
                    value: "\(noShows)",
                    current: Double(noShows),
                    previous: Double(previousNoShows),
                    direction: .lowerIsBetter
                )
            )
        }

        return EmployeeGrowthReport(
            period: period,
            revenue: revenue,
            previousRevenue: previousRevenue,
            visits: current.count,
            metrics: metrics,
            trend: trend(months: period.trendMonths, bookings: earned, now: now),
            services: breakdown(of: current),
            records: records(bookings: earned, blocks: blocks, hours: hours, now: now),
            hasEnoughData: !current.isEmpty
        )
    }

    private struct ClientSplit {
        let new: Int
        let returning: Int

        var total: Int { new + returning }
        var returnRate: Double { total > 0 ? Double(returning) / Double(total) : 0 }
    }

    /// Splits the period's clients into people who came for the first time and people
    /// who had already been before the period started.
    private static func clientSplit(
        current: [Booking],
        allEarned: [Booking],
        range: DateInterval
    ) -> ClientSplit {
        var firstVisit: [String: Date] = [:]
        for booking in allEarned {
            let key = booking.clientID?.uuidString ?? booking.clientName
            if let existing = firstVisit[key] {
                firstVisit[key] = min(existing, booking.start)
            } else {
                firstVisit[key] = booking.start
            }
        }

        let keys = Set(current.map { $0.clientID?.uuidString ?? $0.clientName })
        var newCount = 0
        var returningCount = 0
        for key in keys {
            if let first = firstVisit[key], first >= range.start {
                newCount += 1
            } else {
                returningCount += 1
            }
        }
        return ClientSplit(new: newCount, returning: returningCount)
    }

    private static func occupancyRate(
        in range: DateInterval,
        bookings: [Booking],
        blocks: [TimeBlock],
        hours: [OpeningHours],
        now: Date
    ) -> Double {
        var cursor = AppDate.startOfDay(range.start)
        let end = min(range.end, now)
        var sellable = 0
        var booked = 0
        while cursor < end {
            let day = load(on: cursor, bookings: bookings, blocks: blocks, hours: hours)
            sellable += day.sellableMinutes
            booked += day.bookedMinutes
            guard let next = AppDate.calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return sellable > 0 ? min(Double(booked) / Double(sellable), 1) : 0
    }

    /// Revenue per calendar month, oldest first.
    private static func trend(months: Int, bookings: [Booking], now: Date) -> [MonthlyRevenuePoint] {
        let calendar = AppDate.calendar
        let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now

        return (0..<months).reversed().compactMap { offset -> MonthlyRevenuePoint? in
            guard let start = calendar.date(byAdding: .month, value: -offset, to: thisMonth),
                  let next = calendar.date(byAdding: .month, value: 1, to: start) else { return nil }
            let revenue = bookings
                .filter { $0.start >= start && $0.start < next }
                .reduce(0) { $0 + $1.price }
            return MonthlyRevenuePoint(month: start, revenue: revenue)
        }
    }

    /// Personal bests across the whole recorded history.
    private static func records(
        bookings: [Booking],
        blocks: [TimeBlock],
        hours: [OpeningHours],
        now: Date
    ) -> [PersonalRecord] {
        guard !bookings.isEmpty else { return [] }
        let calendar = AppDate.calendar

        var byMonth: [Date: Double] = [:]
        var byDay: [Date: (revenue: Double, clients: Int)] = [:]
        for booking in bookings {
            let month = calendar.date(from: calendar.dateComponents([.year, .month], from: booking.start)) ?? booking.start
            byMonth[month, default: 0] += booking.price
            let day = AppDate.startOfDay(booking.start)
            let existing = byDay[day] ?? (0, 0)
            byDay[day] = (existing.revenue + booking.price, existing.clients + 1)
        }

        var result: [PersonalRecord] = []

        if let best = byMonth.max(by: { $0.value < $1.value }) {
            result.append(
                PersonalRecord(
                    key: "bestMonth",
                    title: "Geriausias mėnuo",
                    value: best.value.asEuro,
                    detail: best.key.monthText
                )
            )
        }
        if let best = byDay.max(by: { $0.value.revenue < $1.value.revenue }) {
            result.append(
                PersonalRecord(
                    key: "bestDay",
                    title: "Geriausia diena",
                    value: best.value.revenue.asEuro,
                    detail: best.key.dayText
                )
            )
        }
        if let best = byDay.max(by: { $0.value.clients < $1.value.clients }) {
            result.append(
                PersonalRecord(
                    key: "mostClients",
                    title: "Daugiausia klientų per dieną",
                    value: "\(best.value.clients)",
                    detail: best.key.dayText
                )
            )
        }
        if let best = byMonth.keys
            .map({ month -> (Date, Double) in
                let next = calendar.date(byAdding: .month, value: 1, to: month) ?? month
                let rate = occupancyRate(
                    in: DateInterval(start: month, end: next),
                    bookings: bookings,
                    blocks: blocks,
                    hours: hours,
                    now: now
                )
                return (month, rate)
            })
            .max(by: { $0.1 < $1.1 }), best.1 > 0 {
            result.append(
                PersonalRecord(
                    key: "bestOccupancy",
                    title: "Didžiausias mėnesio užimtumas",
                    value: "\(Int((best.1 * 100).rounded())) %",
                    detail: best.0.monthText
                )
            )
        }

        return result
    }
}
