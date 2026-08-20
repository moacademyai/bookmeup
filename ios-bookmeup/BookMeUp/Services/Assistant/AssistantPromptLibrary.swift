import Foundation

/// The example requests that drift through the assistant box.
///
/// They are the fastest way to teach someone what the assistant can do — a client who
/// reads two of them understands they can just say what they need. Kept short on purpose:
/// they have to read as a thought someone would actually have, not as a demo script.
///
/// The list is ordered by the client's own interests, but never cut down to them: a hair
/// client must still see that they can ask for a dentist, because preferences are signals,
/// not restrictions.
nonisolated enum AssistantPromptLibrary {

    /// One example, tied to the category it belongs to.
    struct Prompt: Identifiable, Hashable {
        let id: String
        let text: String
        /// `nil` for examples that are not about one industry.
        let category: ServiceCategory?
    }

    static let all: [Prompt] = [
        Prompt(id: "haircut-today", text: "Kur šiandien galiu apsikirpti?", category: .hair),
        Prompt(id: "massage-evening", text: "Rask masažą rytoj po 18:00", category: .massage),
        Prompt(id: "cheapest-nails", text: "Pigiausias manikiūras aplink mane", category: .nails),
        Prompt(id: "best-barber", text: "Rask geriausiai įvertintą barberį", category: .hair),
        Prompt(id: "dentist-next-week", text: "Noriu dantų higienos kitą savaitę", category: .wellness),
        Prompt(id: "free-today", text: "Kur yra laisva vieta šiandien?", category: nil),
        Prompt(id: "massage-budget", text: "Noriu masažo iki 50 €", category: .massage),
        Prompt(id: "hairdresser-near", text: "Rask kirpėją netoli manęs", category: .hair),
        Prompt(id: "facial-today", text: "Veido valymas šiandien po darbo", category: .beauty),
        Prompt(id: "brows-budget", text: "Antakių korekcija iki 30 €", category: .beauty),
        Prompt(id: "pedicure-lunch", text: "Pedikiūras per pietus", category: .nails),
        Prompt(id: "rating", text: "Salonas su bent 4,8 ★", category: nil),
        Prompt(id: "pilates-morning", text: "Pilatesas rytoj ryte", category: .fitness),
        Prompt(id: "favorite-soonest", text: "Laikas pas mano mėgstamą meistrą", category: nil),
        Prompt(id: "something-new", text: "Noriu išbandyti kažką naujo", category: nil)
    ]

    /// Examples ordered for one client.
    ///
    /// Interests first, then everything else — so the list still ends up showing an
    /// industry the client never picked, which is exactly the point.
    static func prompts(for profile: ClientExperienceProfile?) -> [Prompt] {
        guard let profile else { return all }
        let interests = Set(profile.interestedCategories)
        guard !interests.isEmpty else { return all }

        let preferred = all.filter { prompt in
            guard let category = prompt.category else { return false }
            return interests.contains(category)
        }
        let rest = all.filter { prompt in
            guard let category = prompt.category else { return true }
            return !interests.contains(category)
        }
        return preferred + rest
    }
}
