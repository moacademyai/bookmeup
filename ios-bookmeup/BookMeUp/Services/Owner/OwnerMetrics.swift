import Foundation

/// Turns the salon's real records into the numbers the owner sees.
///
/// Every figure is derived on demand from bookings, attendance and schedules —
/// nothing is stored, nothing is seeded as a "result". When a mechanism that would
/// produce a number does not exist yet, this type returns nothing rather than a
/// plausible-looking one.
@MainActor
enum OwnerMetrics {
    /// The day in numbers for one location.
    static func snapshot(
        store: BookMeUpStore,
        business: BusinessStore,
        on date: Date
    ) -> OwnerTodaySnapshot {
        let bookings = store.salonBookings(on: date)
        let working = business.staffWorking(on: date)
        let openMinutes = business.selectedLocation?.hours.openMinutes(on: date) ?? 0
        let capacity = working.count * openMinutes
        let bookedMinutes = bookings.reduce(0) { $0 + $1.durationMinutes }

        let newClients = bookings.filter { $0.visitNumber <= 1 }.count

        return OwnerTodaySnapshot(
            revenue: bookings.reduce(0) { $0 + $1.price },
            bookings: bookings.count,
            occupancy: capacity > 0 ? min(Double(bookedMinutes) / Double(capacity), 1) : 0,
            newClients: newClients,
            returningClients: bookings.count - newClients,
            cancellations: store.salonCancellations(on: date).count,
            noShows: store.salonNoShows(on: date).count,
            staffWorking: working.count,
            staffTotal: business.activeStaff.count
        )
    }

    /// What genuinely needs a decision right now.
    ///
    /// Three checks run against real data: appointments held for approval, leave
    /// waiting for an answer, and specialists double-booked. The other signals the
    /// owner will eventually want — failed payouts, low stock, integration errors —
    /// need systems this build does not have, so they are not invented here.
    static func actionRequired(
        store: BookMeUpStore,
        business: BusinessStore,
        on date: Date
    ) -> [ActionRequiredItem] {
        var items: [ActionRequiredItem] = []

        for booking in store.pendingApprovalBookings {
            items.append(
                ActionRequiredItem(
                    title: "Rezervacija laukia patvirtinimo",
                    detail: "\(booking.clientName) · \(booking.start.relativeDayTimeText) · \(booking.serviceName)",
                    symbolName: "hourglass",
                    severity: .attention,
                    bookingID: booking.id
                )
            )
        }

        for request in business.pendingLeaveRequests {
            let name = business.staffMember(with: request.staffID)?.memberName ?? "Darbuotojas"
            items.append(
                ActionRequiredItem(
                    title: "\(request.kind.title): \(name)",
                    detail: "\(request.rangeText) · \(request.dayCount) d.",
                    symbolName: request.kind.symbolName,
                    severity: .attention,
                    route: .module(.leave)
                )
            )
        }

        for conflict in store.scheduleConflicts(on: date) {
            items.append(
                ActionRequiredItem(
                    title: "Grafiko konfliktas: \(conflict.specialistName)",
                    detail: "\(conflict.first.start.timeText) ir \(conflict.second.start.timeText) persidengia",
                    symbolName: "exclamationmark.triangle",
                    severity: .critical,
                    bookingID: conflict.first.id
                )
            )
        }

        return items
    }

    /// Revenue the product recovered, per mechanism.
    ///
    /// Returns `nil` for every source whose engine has not been built — the owner sees
    /// an honest "not measured yet", never a number the product cannot stand behind.
    static func recoveredRevenue(for source: RevenueRecoverySource) -> Double? {
        nil
    }
}
