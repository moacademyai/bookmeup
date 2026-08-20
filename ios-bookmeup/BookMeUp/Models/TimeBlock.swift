import Foundation

/// Personal time a specialist reserves for themselves (break, meal, training, custom).
nonisolated struct TimeBlock: Identifiable, Codable, Hashable {
    let id: UUID
    let specialistName: String
    var title: String
    var start: Date
    var durationMinutes: Int

    init(
        id: UUID = UUID(),
        specialistName: String,
        title: String,
        start: Date,
        durationMinutes: Int
    ) {
        self.id = id
        self.specialistName = specialistName
        self.title = title
        self.start = start
        self.durationMinutes = durationMinutes
    }

    var end: Date { start.addingTimeInterval(TimeInterval(durationMinutes * 60)) }
}

/// Ready-made block durations so blocking time takes two taps, not a form.
nonisolated enum BlockPreset: String, CaseIterable, Identifiable {
    case shortBreak
    case meal
    case sport
    case meeting
    case timeOff

    var id: String { rawValue }

    var title: String {
        switch self {
        case .shortBreak: "Pertrauka"
        case .meal: "Maistas"
        case .sport: "Sportas"
        case .meeting: "Susitikimas"
        case .timeOff: "Nedarbas"
        }
    }

    var minutes: Int {
        switch self {
        case .shortBreak: 15
        case .meal: 30
        case .sport: 60
        case .meeting: 45
        case .timeOff: 120
        }
    }

    var symbolName: String {
        switch self {
        case .shortBreak: "cup.and.saucer"
        case .meal: "fork.knife"
        case .sport: "figure.run"
        case .meeting: "person.2"
        case .timeOff: "moon.zzz"
        }
    }
}
