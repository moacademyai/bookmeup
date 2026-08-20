import Foundation

/// The business account everything else hangs from.
///
/// A business owns locations; locations own staff, services, resources and stock.
/// Market settings live here so nothing downstream has to assume a country, a
/// currency or a language.
nonisolated struct Business: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var legalName: String
    var about: String
    var phone: String
    var email: String
    var website: String
    /// ISO region — drives phone formatting, tax presentation and marketplace market.
    var countryCode: String
    var currencyCode: String
    var defaultLanguage: String
    var timeZoneIdentifier: String
    var vatRegistered: Bool
    var vatNumber: String?
    var vatRatePercent: Double?
    var logoAssetName: String?

    init(
        id: UUID = UUID(),
        name: String,
        legalName: String = "",
        about: String = "",
        phone: String = "",
        email: String = "",
        website: String = "",
        countryCode: String = "LT",
        currencyCode: String = "EUR",
        defaultLanguage: String = "lt",
        timeZoneIdentifier: String = "Europe/Vilnius",
        vatRegistered: Bool = false,
        vatNumber: String? = nil,
        vatRatePercent: Double? = nil,
        logoAssetName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.legalName = legalName
        self.about = about
        self.phone = phone
        self.email = email
        self.website = website
        self.countryCode = countryCode
        self.currencyCode = currencyCode
        self.defaultLanguage = defaultLanguage
        self.timeZoneIdentifier = timeZoneIdentifier
        self.vatRegistered = vatRegistered
        self.vatNumber = vatNumber
        self.vatRatePercent = vatRatePercent
        self.logoAssetName = logoAssetName
    }

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    var countryName: String {
        Locale(identifier: "lt_LT").localizedString(forRegionCode: countryCode)?.capitalizedFirst ?? countryCode
    }

    var marketText: String {
        "\(countryName) · \(currencyCode) · \(defaultLanguage.uppercased())"
    }

    var vatText: String {
        guard vatRegistered else { return "PVM mokėtojas: ne" }
        let rate = vatRatePercent.map { "\(Int($0))%" } ?? "nenurodyta"
        return "PVM \(rate) · \(vatNumber ?? "kodas nenurodytas")"
    }
}
