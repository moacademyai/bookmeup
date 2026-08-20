import Foundation

/// Top-level marketplace categories.
///
/// This is the platform's category list, shared by providers, discovery filters, the
/// assistant and the Client Experience questionnaire. It is deliberately not limited to
/// beauty: BookMeUp is a service-booking platform, so health, fitness and home services
/// belong here too, and more industries can be appended without touching stored data —
/// the raw values are the contract.
nonisolated enum ServiceCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case hair
    case nails
    case beauty
    case massage
    case wellness
    case fitness
    case home

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hair: "Plaukai"
        case .nails: "Nagai"
        case .beauty: "Grožis"
        case .massage: "Masažas"
        case .wellness: "Sveikata"
        case .fitness: "Sportas"
        case .home: "Namai"
        }
    }

    var symbolName: String {
        switch self {
        case .hair: "scissors"
        case .nails: "hand.raised"
        case .beauty: "sparkles"
        case .massage: "hands.and.sparkles"
        case .wellness: "heart.text.square"
        case .fitness: "figure.pilates"
        case .home: "house"
        }
    }

    /// One line explaining what the category covers — used where a client is choosing
    /// between industries rather than between salons.
    var summary: String {
        switch self {
        case .hair: "Kirpimai, dažymas, barzda"
        case .nails: "Manikiūras ir pedikiūras"
        case .beauty: "Veido procedūros, antakiai, blakstienos"
        case .massage: "Atpalaiduojantis ir gydomasis masažas"
        case .wellness: "Odontologija, fizioterapija, sveikata"
        case .fitness: "Treniruotės ir kūno praktikos"
        case .home: "Paslaugos namams ir progoms"
        }
    }
}
