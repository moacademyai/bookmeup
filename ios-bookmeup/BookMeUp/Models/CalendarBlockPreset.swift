import Foundation

/// A specialist's own saved block preset (title + duration).
///
/// The list is provided by the data layer today; when specialists can edit their
/// presets the same type will back that screen.
nonisolated struct PersonalBlockPreset: Identifiable, Hashable {
    let id: UUID
    let title: String
    let minutes: Int
    let symbolName: String

    init(id: UUID = UUID(), title: String, minutes: Int, symbolName: String) {
        self.id = id
        self.title = title
        self.minutes = minutes
        self.symbolName = symbolName
    }

    var durationText: String {
        minutes % 60 == 0 && minutes >= 60 ? "\(minutes / 60) val." : "\(minutes) min."
    }
}
