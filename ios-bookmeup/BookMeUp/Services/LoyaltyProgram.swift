import Foundation

/// Works out a client's loyalty standing from the visits they actually had.
///
/// There is no loyalty backend yet, so nothing here is stored: the balance is derived
/// from completed, non-cancelled bookings every time it is read. That makes it impossible
/// for the app to show points that no real record backs, and it means the day a loyalty
/// service exists, only this file changes.
nonisolated enum LoyaltyProgram {
    /// Points earned per euro spent. The one rule the whole program rests on.
    static let pointsPerEuro = 10

    static let rewards: [LoyaltyReward] = [
        LoyaltyReward(
            id: "discount-10",
            title: "10 % nuolaida vizitui",
            detail: "Galioja bet kuriai paslaugai BookMeUp",
            cost: 500,
            symbolName: "tag"
        ),
        LoyaltyReward(
            id: "care-product",
            title: "Priežiūros priemonė",
            detail: "Meistro parinkta priemonė po vizito",
            cost: 900,
            symbolName: "gift"
        ),
        LoyaltyReward(
            id: "priority",
            title: "Prioritetinis laikas",
            detail: "Pirmumas populiariausiems vakaro laikams",
            cost: 1500,
            symbolName: "clock.badge.checkmark"
        )
    ]

    /// Builds the account from a client's own history.
    static func account(from bookings: [Booking]) -> LoyaltyAccount {
        let earned = bookings
            .filter { $0.status != .cancelled && $0.end <= Date() }
            .sorted { $0.start > $1.start }

        let history = earned.map { booking in
            LoyaltyEntry(
                id: booking.id,
                title: booking.providerName,
                detail: "\(booking.serviceName) · \(booking.start.dayText)",
                points: points(for: booking.price),
                date: booking.start
            )
        }

        let total = history.reduce(0) { $0 + $1.points }
        return LoyaltyAccount(
            points: total,
            lifetimePoints: total,
            history: history,
            source: .demoProgram
        )
    }

    static func points(for amount: Double) -> Int {
        Int((amount * Double(pointsPerEuro)).rounded())
    }
}
