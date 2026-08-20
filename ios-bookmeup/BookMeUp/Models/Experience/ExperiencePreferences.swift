import Foundation

/// The structured answers of the Client Experience Profile.
///
/// Every one of these is a stable case, never a rendered Lithuanian string. Business
/// logic, the employee summary and any future export all read the case; only the
/// `title` property turns it into words, so the product stays translatable.
///
/// These preferences describe **how the client would like to be served**. They are not
/// a personality assessment and must never be phrased as one.

// MARK: - Consultation

/// How much the client wants to talk through the result before it starts.
nonisolated enum ConsultationPreference: String, Codable, CaseIterable, Hashable, Identifiable {
    case wantsRecommendations
    case shortDiscussion
    case knowsWhatTheyWant

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wantsRecommendations: "Noriu meistro rekomendacijų"
        case .shortDiscussion: "Trumpai aptarti"
        case .knowsWhatTheyWant: "Dažniausiai jau žinau, ko noriu"
        }
    }

    var detail: String {
        switch self {
        case .wantsRecommendations: "Pasiūlykite, kas tiktų geriausiai"
        case .shortDiscussion: "Kelios minutės prieš pradedant"
        case .knowsWhatTheyWant: "Ateinu su aiškiu sprendimu"
        }
    }

    var symbolName: String {
        switch self {
        case .wantsRecommendations: "lightbulb"
        case .shortDiscussion: "bubble.left.and.bubble.right"
        case .knowsWhatTheyWant: "checkmark.circle"
        }
    }
}

// MARK: - Visit priorities

/// What the client values most during the visit. Multiple answers are allowed and V1
/// deliberately does not ask for ranking.
nonisolated enum VisitPriority: String, Codable, CaseIterable, Hashable, Identifiable {
    case result
    case speed
    case comfort
    case atmosphere
    case recommendations

    var id: String { rawValue }

    var title: String {
        switch self {
        case .result: "Rezultatas"
        case .speed: "Greitis"
        case .comfort: "Komfortas"
        case .atmosphere: "Pokalbis / atmosfera"
        case .recommendations: "Meistro rekomendacijos"
        }
    }

    var symbolName: String {
        switch self {
        case .result: "sparkles"
        case .speed: "bolt"
        case .comfort: "leaf"
        case .atmosphere: "bubble.left.and.bubble.right"
        case .recommendations: "hand.thumbsup"
        }
    }
}

// MARK: - Communication

/// How the client likes the conversation during the visit.
///
/// This is a service preference. It must never be rendered as a label about the person
/// ("tylus žmogus", "nemėgsta kalbėti") anywhere in the product.
nonisolated enum CommunicationPreference: String, Codable, CaseIterable, Hashable, Identifiable {
    case social
    case adaptive
    case quiet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .social: "Mėgstu pabendrauti"
        case .adaptive: "Priklauso nuo nuotaikos"
        case .quiet: "Mėgstu ramų vizitą"
        }
    }

    var detail: String {
        switch self {
        case .social: "Pokalbis vizitą daro maloniu"
        case .adaptive: "Kartais taip, kartais ne"
        case .quiet: "Tyla man yra poilsis"
        }
    }

    var symbolName: String {
        switch self {
        case .social: "bubble.left.and.bubble.right"
        case .adaptive: "arrow.triangle.2.circlepath"
        case .quiet: "moon"
        }
    }
}

// MARK: - Product recommendations

/// Whether the client wants aftercare and product suggestions from the specialist.
///
/// This is a service preference inside the visit. It is **not** marketing consent and
/// must never be used to justify sending campaigns.
nonisolated enum ProductRecommendationPreference: String, Codable, CaseIterable, Hashable, Identifiable {
    case yes
    case onlyIfRelevant
    case no

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yes: "Taip"
        case .onlyIfRelevant: "Tik jei tikrai tinka"
        case .no: "Ne"
        }
    }

    var detail: String {
        switch self {
        case .yes: "Mielai išgirsiu, kuo prižiūrėti"
        case .onlyIfRelevant: "Tik jei tikrai reikia man"
        case .no: "Nesiūlykite, ačiū"
        }
    }

    var symbolName: String {
        switch self {
        case .yes: "hand.thumbsup"
        case .onlyIfRelevant: "checkmark.circle"
        case .no: "hand.raised"
        }
    }
}

// MARK: - Hospitality

/// One drink or welcome gesture a business offers at the start of a visit.
///
/// Deliberately data, not an enum: one business pours coffee and water, another adds
/// tea, a third offers nothing at all. The options belong to the business, so this type
/// can later be filled from Owner configuration without touching the client flow.
nonisolated struct HospitalityOption: Identifiable, Codable, Hashable {
    /// Stable id stored on the profile — never the rendered title.
    let id: String
    var title: String
    var symbolName: String

    init(id: String, title: String, symbolName: String) {
        self.id = id
        self.title = title
        self.symbolName = symbolName
    }

    /// The "nothing, thank you" answer. A business that offers hospitality always needs
    /// a way for the client to decline it.
    static let declined = HospitalityOption(id: "none", title: "Nieko", symbolName: "hand.raised")
}
