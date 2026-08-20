import SwiftUI

/// Blocking time straight from the calendar: pick a preset, the duration follows.
struct CalendarBlockSheet: View {
    let start: Date
    /// The calendar the block lands in.
    var specialistName: String
    var onSaved: (String, Date, Int) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var startDate: Date
    @State private var selection: Selection
    @State private var minutes: Int
    @State private var customTitle = ""

    init(start: Date, specialistName: String, onSaved: @escaping (String, Date, Int) -> Void) {
        self.start = start
        self.specialistName = specialistName
        self.onSaved = onSaved
        _startDate = State(initialValue: start)
        _selection = State(initialValue: .standard(.shortBreak))
        _minutes = State(initialValue: BlockPreset.shortBreak.minutes)
    }

    private enum Selection: Hashable {
        case standard(BlockPreset)
        case personal(UUID)
        case custom
    }

    private var title: String {
        switch selection {
        case .standard(let preset):
            return preset.title
        case .personal(let id):
            return SampleData.personalBlockPresets.first { $0.id == id }?.title ?? "Asmeninis laikas"
        case .custom:
            let trimmed = customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Asmeninis laikas" : trimmed
        }
    }

    private var end: Date { startDate.addingTimeInterval(TimeInterval(minutes * 60)) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Presetai") {
                    ForEach(BlockPreset.allCases) { preset in
                        presetRow(
                            title: preset.title,
                            symbol: preset.symbolName,
                            minutes: preset.minutes,
                            isSelected: selection == .standard(preset)
                        ) {
                            selection = .standard(preset)
                            minutes = preset.minutes
                        }
                    }
                }

                Section("Mano presetai") {
                    ForEach(SampleData.personalBlockPresets) { preset in
                        presetRow(
                            title: preset.title,
                            symbol: preset.symbolName,
                            minutes: preset.minutes,
                            isSelected: selection == .personal(preset.id)
                        ) {
                            selection = .personal(preset.id)
                            minutes = preset.minutes
                        }
                    }
                }

                Section("Kita") {
                    Button {
                        selection = .custom
                    } label: {
                        HStack {
                            Label("Savas pavadinimas", systemImage: "square.and.pencil")
                                .foregroundStyle(CalendarTheme.label)
                            Spacer(minLength: 8)
                            if selection == .custom {
                                Image(systemName: "checkmark")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(CalendarTheme.accent)
                            }
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)

                    if selection == .custom {
                        TextField("Pavadinimas", text: $customTitle)
                            .textInputAutocapitalization(.sentences)
                    }
                }

                Section("Laikas") {
                    DatePicker("Pradžia", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    Stepper {
                        HStack {
                            Text("Trukmė")
                            Spacer(minLength: 8)
                            Text(durationText)
                                .monospacedDigit()
                                .foregroundStyle(CalendarTheme.secondary)
                        }
                    } onIncrement: {
                        minutes = min(minutes + 15, 480)
                    } onDecrement: {
                        minutes = max(minutes - 15, 15)
                    }
                    LabeledContent("Pabaiga") {
                        Text(end.timeText)
                            .monospacedDigit()
                            .foregroundStyle(CalendarTheme.secondary)
                    }
                }
            }
            .navigationTitle("Blokuoti laiką")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Atšaukti") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Išsaugoti") {
                        onSaved(title, startDate, minutes)
                        dismiss()
                    }
                }
            }
        }
    }

    private var durationText: String {
        if minutes >= 60 && minutes % 60 == 0 { return "\(minutes / 60) val." }
        if minutes > 60 { return "\(minutes / 60) val. \(minutes % 60) min." }
        return "\(minutes) min."
    }

    private func presetRow(
        title: String,
        symbol: String,
        minutes presetMinutes: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: symbol)
                    .foregroundStyle(CalendarTheme.label)
                Spacer(minLength: 8)
                Text(presetMinutes >= 60 && presetMinutes % 60 == 0 ? "\(presetMinutes / 60) val." : "\(presetMinutes) min.")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(CalendarTheme.secondary)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CalendarTheme.accent)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
