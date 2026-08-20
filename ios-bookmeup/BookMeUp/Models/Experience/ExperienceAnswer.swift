import Foundation

/// One stored answer.
///
/// Selections keep stable option ids, never rendered titles, and a text answer keeps
/// exactly what the client wrote. Both shapes cover every question kind in V1, which is
/// why adding a question never changes the profile model.
nonisolated enum ExperienceAnswer: Codable, Hashable {
    case selection(Set<String>)
    case text(String)

    /// Selected option ids, or an empty set for a text answer.
    var optionIDs: Set<String> {
        switch self {
        case .selection(let ids): ids
        case .text: []
        }
    }

    /// The single chosen id, for single-select questions.
    var singleOptionID: String? {
        switch self {
        case .selection(let ids): ids.first
        case .text: nil
        }
    }

    /// The written answer, trimmed, or `nil` when nothing meaningful was typed.
    var textValue: String? {
        guard case .text(let value) = self else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// An answer the client has effectively not given. Empty answers are dropped on
    /// save so an untouched question never looks answered.
    var isEmpty: Bool {
        switch self {
        case .selection(let ids): ids.isEmpty
        case .text: textValue == nil
        }
    }

    func contains(_ optionID: String) -> Bool {
        optionIDs.contains(optionID)
    }

    /// Applies a tap on one option, respecting whether the question takes many answers.
    func toggling(_ optionID: String, allowsMultiple: Bool) -> ExperienceAnswer {
        guard allowsMultiple else { return .selection([optionID]) }
        var ids = optionIDs
        if ids.contains(optionID) {
            ids.remove(optionID)
        } else {
            ids.insert(optionID)
        }
        return .selection(ids)
    }
}
