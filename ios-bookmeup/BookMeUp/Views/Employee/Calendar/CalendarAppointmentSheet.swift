import SwiftUI

/// New appointment started from the calendar. Date and time arrive prefilled from
/// the spot the specialist pressed. Saving goes through the existing booking store.
struct CalendarAppointmentSheet: View {
    let start: Date
    /// Whose calendar this appointment belongs to. An employee helping a colleague
    /// books into their column, so this is not always the signed-in specialist.
    let specialistName: String
    var onSaved: (Booking) -> Void

    @Environment(BookMeUpStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var startDate: Date
    @State private var clientName: String?
    @State private var service: ServiceOffering
    @State private var note = ""
    @State private var query = ""
    /// Non-nil while the shared create-client form is up. The booking keeps its time,
    /// service and note underneath it.
    @State private var newClientPrefill: NewClientPrefill?
    /// Set while the store is writing, so a second tap cannot create a second booking.
    @State private var isSaving = false
    @State private var conflict: CalendarConflict?
    @FocusState private var isSearchFocused: Bool

    init(start: Date, specialistName: String, onSaved: @escaping (Booking) -> Void) {
        self.start = start
        self.specialistName = specialistName
        self.onSaved = onSaved
        _startDate = State(initialValue: start)
        _service = State(initialValue: SampleData.studioNoma.services[0])
    }

    private var provider: Provider {
        store.providers.first { $0.specialistName == specialistName } ?? SampleData.studioNoma
    }

    private var isColleague: Bool { specialistName != store.specialistName }

    private var end: Date {
        startDate.addingTimeInterval(TimeInterval(service.durationMinutes * 60))
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Uses the shared client base and its search: name, surname, phone, or "Kipras 948".
    private var results: [Client] {
        guard !trimmedQuery.isEmpty else { return [] }
        return Array(store.specialistClients(matching: trimmedQuery).prefix(6))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Specialistas") {
                    LabeledContent("Kalendorius") {
                        Text(specialistName)
                            .foregroundStyle(isColleague ? CalendarTheme.accent : CalendarTheme.secondary)
                    }
                    if isColleague {
                        Text("Rezervacija bus sukurta kolegos kalendoriuje.")
                            .font(.caption)
                            .foregroundStyle(CalendarTheme.secondary)
                    }
                }

                Section("Klientas") {
                    if let clientName {
                        selectedClientRow(clientName)
                    } else {
                        searchField
                        searchResults
                        actionRow(
                            title: trimmedQuery.isEmpty
                                ? "Naujas klientas"
                                : "Sukurti naują klientą · \(trimmedQuery)",
                            symbol: "person.badge.plus"
                        ) {
                            isSearchFocused = false
                            newClientPrefill = .from(query: trimmedQuery)
                        }
                        actionRow(title: "Walk-in klientas", symbol: "figure.walk") {
                            select("Walk-in klientas")
                        }
                    }
                }

                Section("Laikas") {
                    DatePicker("Pradžia", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    LabeledContent("Pabaiga") {
                        Text(end.timeText)
                            .monospacedDigit()
                            .foregroundStyle(CalendarTheme.secondary)
                    }
                }

                Section("Paslauga") {
                    ForEach(provider.services) { item in
                        Button {
                            service = item
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .foregroundStyle(CalendarTheme.label)
                                    Text("\(item.durationText) · \(item.priceText)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(CalendarTheme.secondary)
                                }
                                Spacer(minLength: 8)
                                if item.id == service.id {
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

                Section("Pastaba") {
                    TextField("Pastaba apie vizitą", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }

                // Availability is checked on save, but showing the clash while the
                // form is still open saves a round trip.
                if let conflict {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(conflict.message)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Palette.terracotta)
                            if let detail = conflict.detail {
                                Text(detail)
                                    .font(.caption)
                                    .foregroundStyle(CalendarTheme.secondary)
                            }
                            Text("Pasirink kitą laiką.")
                                .font(.caption)
                                .foregroundStyle(CalendarTheme.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Nauja rezervacija")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Atšaukti") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Išsaugoti", action: save)
                        .disabled(clientName == nil || isSaving)
                }
            }
            .sheet(item: $newClientPrefill) { prefill in
                NewClientSheet(prefill: prefill, duplicateActionTitle: "Pasirinkti klientą") { client in
                    select(client.fullName)
                    query = ""
                }
                .environment(store)
            }
        }
    }

    // MARK: - Client search

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(CalendarTheme.secondary)
            TextField("Ieškoti kliento: vardas, telefonas, „Kipras 948“", text: $query)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(CalendarTheme.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        if trimmedQuery.isEmpty {
            Text("Įvesk vardą, telefoną arba vardą su paskutiniais numerio skaičiais.")
                .font(.caption)
                .foregroundStyle(CalendarTheme.secondary)
        } else if results.isEmpty {
            Text("Klientų nerasta")
                .font(.caption)
                .foregroundStyle(CalendarTheme.secondary)
        } else {
            ForEach(results) { client in
                Button {
                    select(client.fullName)
                } label: {
                    clientRow(name: client.fullName, detail: subtitle(for: client), initials: client.initials)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func selectedClientRow(_ name: String) -> some View {
        HStack(spacing: 12) {
            clientRow(name: name, detail: detail(for: name), initials: initials(for: name))
            Button("Keisti") {
                clientName = nil
                query = ""
                isSearchFocused = true
            }
            .font(.footnote.weight(.semibold))
            .buttonStyle(.plain)
            .foregroundStyle(CalendarTheme.accent)
        }
    }

    private func clientRow(name: String, detail: String, initials: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(CalendarTheme.fill)
                .frame(width: 34, height: 34)
                .overlay {
                    Text(initials)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CalendarTheme.secondary)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CalendarTheme.label)
                if !detail.isEmpty {
                    Text(detail)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(CalendarTheme.secondary)
                }
            }
            Spacer(minLength: 4)
        }
        .contentShape(.rect)
    }

    private func actionRow(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.subheadline)
                .foregroundStyle(CalendarTheme.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func subtitle(for client: Client) -> String {
        if client.hasPhone { return client.phoneDisplay }
        let visits = store.overview(for: client).totalVisits
        return visits > 0 ? "\(visits) vizitai" : "Naujas klientas"
    }

    private func detail(for name: String) -> String {
        guard let match = store.client(named: name) else { return "Naujas klientas" }
        return subtitle(for: match)
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first }.map(String.init).joined().uppercased()
    }

    private func select(_ name: String) {
        clientName = name
        isSearchFocused = false
    }

    /// Creates the appointment, or reports the clash and keeps the form open.
    ///
    /// Guarded against a double tap: the button is disabled for the duration, and the
    /// sheet only closes once the store has actually accepted the booking.
    private func save() {
        guard let clientName, !isSaving else { return }
        isSaving = true

        let outcome = store.createBooking(
            forSpecialist: specialistName,
            clientName: clientName,
            service: service,
            at: startDate,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        switch outcome {
        case .created(let booking):
            conflict = nil
            onSaved(booking)
            dismiss()
        case .conflict(let found):
            conflict = found
            isSaving = false
        }
    }
}
