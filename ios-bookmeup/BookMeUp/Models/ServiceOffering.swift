import Foundation

/// A bookable service with its duration and price.
nonisolated struct ServiceOffering: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let durationMinutes: Int
    let price: Double
    let detail: String

    init(id: UUID = UUID(), name: String, durationMinutes: Int, price: Double, detail: String = "") {
        self.id = id
        self.name = name
        self.durationMinutes = durationMinutes
        self.price = price
        self.detail = detail
    }

    var durationText: String { "\(durationMinutes) min." }

    var priceText: String { price.asEuro }
}

nonisolated extension Double {
    /// Formats an amount as euros without trailing decimals for round numbers.
    var asEuro: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale(identifier: "lt_LT")
        formatter.maximumFractionDigits = self.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: self)) ?? "\(Int(self)) €"
    }
}
