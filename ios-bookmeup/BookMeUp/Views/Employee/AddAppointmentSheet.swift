import SwiftUI

/// Manual booking by the specialist: forgiving client search, service, time.
///
/// Opened from the client profile it arrives with that client already chosen.
struct AddAppointmentSheet: View {
    let date: Date
    var presetClient: Client?
    var onCreated: (String) -> Void

    @Environment(BookMeUpStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var clientName = ""
    @State private var isWalkIn = false
    @State private var selectedService: ServiceOffering?
    @State private var start: Date
    /// Non-nil while the shared create-client form is up. The booking keeps its time,
    /// service and client search underneath it.
    @State private var newClientPrefill: NewClientPrefill?
    /// Set while the store is writing, so a double tap cannot create two appointments.
    @State private var isSaving = false
    @State private var conflict: CalendarConflict?

    init(date: Date, presetClient: Client? = nil, onCreated: @escaping (String) -> Void) {
        self.date = date
        self.presetClient = presetClient
        self.onCreated = onCreated
        _start = State(initialValue: AppDate.time(15, 0, dayOffset: date.daysFromNow))
        _clientName = State(initialValue: presetClient?.fullName ?? "")
        _query = State(initialValue: presetClient?.fullName ?? "")
    }

    private var provider: Provider { SampleData.studioNoma }

    private var service: ServiceOffering { selectedService ?? provider.services[0] }

    private var matches: [Client] {
        store.specialistClients(matching: query)
    }

    private var canSave: Bool { isWalkIn || !clientName.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    clientSection
                    serviceSection
                    timeSection
                    conflictNotice
                    saveButton
                }
                .padding(20)
            }
            .background(Palette.bone)
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Nauja rezervacija")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Uždaryti") { dismiss() }
                }
            }
            .sheet(item: $newClientPrefill) { prefill in
                NewClientSheet(prefill: prefill, duplicateActionTitle: "Pasirinkti klientą") { client in
                    select(client)
                }
                .environment(store)
            }
        }
        .presentationDetents([.large])
        .presentationContentInteraction(.scrolls)
    }

    /// The created client continues in this same booking, nothing else is reset.
    private func select(_ client: Client) {
        clientName = client.fullName
        query = client.fullName
        isWalkIn = false
    }

    private var clientSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Klientas", accessory: clientName.isEmpty ? nil : clientName)

            TextField("Vardas, pavardė arba tel. nr.", text: $query)
                .textInputAutocapitalization(.words)
                .padding(14)
                .background(Palette.surface, in: .rect(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14).stroke(Palette.hairline, lineWidth: 1)
                }

            VStack(spacing: 8) {
                ForEach(matches.prefix(4)) { client in
                    Button {
                        clientName = client.fullName
                        isWalkIn = false
                        query = client.fullName
                    } label: {
                        HStack(spacing: 12) {
                            InitialsAvatar(name: client.fullName, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(client.fullName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Palette.ink)
                                Text(client.hasPhone ? client.phoneDisplay : "Numeris nenurodytas")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(Palette.inkSoft)
                            }
                            Spacer(minLength: 4)
                            if clientName == client.fullName {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Palette.forest)
                            }
                        }
                        .cardSurface(padding: 12, cornerRadius: 16)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    newClientPrefill = .from(query: query)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(Palette.forest)
                            .frame(width: 40, height: 40)
                            .background(Palette.eucalyptus.opacity(0.4), in: .circle)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Naujas klientas")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Palette.ink)
                            Text(
                                query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? "Sukurk ir tęsk šią rezervaciją"
                                    : "Sukurti · \(query.trimmingCharacters(in: .whitespacesAndNewlines))"
                            )
                            .font(.caption)
                            .foregroundStyle(Palette.inkSoft)
                            .lineLimit(1)
                        }
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Palette.inkSoft.opacity(0.7))
                    }
                    .cardSurface(padding: 12, cornerRadius: 16)
                }
                .buttonStyle(.plain)

                Button {
                    isWalkIn = true
                    clientName = "Walk-in klientas"
                    query = ""
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "figure.walk")
                            .foregroundStyle(Palette.forest)
                            .frame(width: 40, height: 40)
                            .background(Palette.eucalyptus.opacity(0.4), in: .circle)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Walk-in klientas")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Palette.ink)
                            Text("Be pilnos registracijos")
                                .font(.caption)
                                .foregroundStyle(Palette.inkSoft)
                        }
                        Spacer(minLength: 4)
                        if isWalkIn {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Palette.forest)
                        }
                    }
                    .cardSurface(padding: 12, cornerRadius: 16)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var serviceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Paslauga")
            VStack(spacing: 0) {
                ForEach(provider.services) { item in
                    Button {
                        selectedService = item
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Palette.ink)
                                Text("\(item.durationText) · \(item.priceText)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(Palette.inkSoft)
                            }
                            Spacer(minLength: 8)
                            Image(systemName: service.id == item.id ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(service.id == item.id ? Palette.forest : Palette.hairline)
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    if item.id != provider.services.last?.id {
                        Divider().overlay(Palette.hairline)
                    }
                }
            }
            .cardSurface()
        }
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Laikas")
            DatePicker("Pradžia", selection: $start, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .tint(Palette.forest)
                .cardSurface()
        }
    }

    /// The clash, when the chosen time is not actually free.
    @ViewBuilder
    private var conflictNotice: some View {
        if let conflict {
            VStack(alignment: .leading, spacing: 4) {
                Text(conflict.message)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.terracotta)
                if let detail = conflict.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Palette.inkSoft)
                }
                Text("Pasirink kitą laiką.")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(padding: 14, cornerRadius: 16)
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            Text("Išsaugoti rezervaciją")
        }
        .buttonStyle(MarigoldButtonStyle(isDisabled: !canSave || isSaving))
        .disabled(!canSave || isSaving)
    }

    /// Success is reported only once the store has actually accepted the booking; a
    /// clash leaves the form exactly as it was so the time can be changed.
    private func save() {
        guard canSave, !isSaving else { return }
        isSaving = true

        let outcome = store.createBooking(
            forSpecialist: store.specialistName,
            clientName: clientName.isEmpty ? "Walk-in klientas" : clientName,
            service: service,
            at: start
        )

        switch outcome {
        case .created(let booking):
            conflict = nil
            onCreated("Rezervacija sukurta · \(booking.start.relativeDayTimeText)")
            dismiss()
        case .conflict(let found):
            conflict = found
            isSaving = false
        }
    }
}
