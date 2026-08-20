import SwiftUI

/// Describes what the booking sheet should do: create a new visit or move an existing one.
struct BookingFlow: Identifiable {
    let id = UUID()
    let provider: Provider
    var service: ServiceOffering?
    var rescheduling: Booking?
    var clientName: String?
    /// A time the client already chose elsewhere — for example a slot tapped on an
    /// assistant result. The sheet opens on that day with the slot selected, so the
    /// booking is one confirmation away instead of a search repeated.
    var preselectedSlot: Date?
    /// The master the client already picked — for example from the business profile.
    /// The sheet opens on that person instead of "no preference".
    var specialistName: String?
}

/// Focused native sheet for choosing a service, a master, a day and a time.
///
/// The order is the order the decision is actually made in: what, with whom, and only
/// then when — because the master determines which times exist at all. Availability is
/// always read for one person's own day, so two colleagues in the same salon can hold
/// the same hour and a busy master simply stops offering it.
struct BookingSheet: View {
    let flow: BookingFlow
    var onCompleted: (Booking) -> Void = { _ in }

    @Environment(BookMeUpStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedService: ServiceOffering
    @State private var selectedDay: Date
    @State private var selectedSlot: Date?
    /// The chosen master, or `nil` for "no preference".
    @State private var selectedSpecialistName: String?
    /// Everyone who can perform the service, with their availability for `selectedDay`.
    /// Held in state because it is a real computation, not something a view body should
    /// redo on every render.
    @State private var options: [SpecialistOption] = []
    /// The usual-master preselection runs once, and never fights a later manual choice.
    @State private var didApplyUsualSpecialist = false

    init(flow: BookingFlow, onCompleted: @escaping (Booking) -> Void = { _ in }) {
        self.flow = flow
        self.onCompleted = onCompleted
        let service = flow.service
            ?? flow.provider.services.first { $0.name == flow.rescheduling?.serviceName }
            ?? flow.provider.services[0]
        _selectedService = State(initialValue: service)
        _selectedDay = State(initialValue: AppDate.startOfDay(flow.preselectedSlot ?? flow.provider.nextSlot))
        _selectedSlot = State(initialValue: flow.preselectedSlot)
        _selectedSpecialistName = State(
            initialValue: flow.rescheduling?.specialistName ?? flow.specialistName
        )
    }

    private var days: [Date] {
        (0..<14).map { AppDate.time(9, 0, dayOffset: $0) }
    }

    /// The times on offer: one master's own day, or everyone's when the client has no
    /// preference.
    private var slots: [Date] {
        guard let selectedSpecialistName else { return options.combinedSlots }
        return options.option(named: selectedSpecialistName)?.slots ?? []
    }

    private var isRescheduling: Bool { flow.rescheduling != nil }

    /// Shown only when the business actually has more than one person to choose from.
    private var showsSpecialistPicker: Bool { !isRescheduling && options.count > 1 }

    /// Who will perform the visit if it is confirmed right now.
    private var assignedSpecialist: TeamMember? {
        if let selectedSpecialistName {
            return options.option(named: selectedSpecialistName)?.member
        }
        guard let selectedSlot else { return nil }
        return options.assignee(for: selectedSlot)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    summary
                    if !isRescheduling && flow.provider.services.count > 1 {
                        servicePicker
                    }
                    if showsSpecialistPicker {
                        SpecialistPicker(
                            options: options,
                            selectedName: $selectedSpecialistName,
                            usualName: store.usualSpecialistName(at: flow.provider)
                        )
                    }
                    dayPicker
                    timeGrid
                    reassurance
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Palette.bone)
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(isRescheduling ? "Pakeisti laiką" : "Pasirinkti laiką")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Uždaryti") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                confirmBar
            }
        }
        .presentationDetents([.large])
        .presentationContentInteraction(.scrolls)
        .task { refreshOptions() }
        .onChange(of: selectedDay) { _, _ in
            selectedSlot = nil
            refreshOptions()
        }
        .onChange(of: selectedService) { _, _ in
            selectedSlot = nil
            refreshOptions()
        }
        .onChange(of: selectedSpecialistName) { _, _ in
            // A time only means something for the person who holds it.
            if let selectedSlot, !slots.contains(selectedSlot) { self.selectedSlot = nil }
        }
    }

    // MARK: - Availability

    /// Recomputes who is free, for the service and day currently chosen.
    private func refreshOptions() {
        if let existing = flow.rescheduling {
            options = [rescheduleOption(for: existing)]
            selectedSpecialistName = existing.specialistName
            return
        }

        options = store.specialistOptions(
            at: flow.provider,
            service: selectedService,
            on: selectedDay
        )

        // A master chosen earlier who cannot perform the new service is dropped rather
        // than silently kept — the alternative is booking the wrong person.
        if let name = selectedSpecialistName, options.option(named: name) == nil {
            selectedSpecialistName = nil
        }
        applyUsualSpecialistIfNeeded()
    }

    /// Moving a visit never changes who performs it, so the sheet works with exactly one
    /// person: the master this appointment already belongs to.
    private func rescheduleOption(for booking: Booking) -> SpecialistOption {
        let member = store.specialists(at: flow.provider).first { $0.name == booking.specialistName }
            ?? TeamMember(
                name: booking.specialistName,
                craft: flow.provider.craft,
                providerID: flow.provider.id
            )
        return SpecialistOption(
            member: member,
            slots: store.availableSlots(
                for: flow.provider,
                specialistName: booking.specialistName,
                on: selectedDay,
                durationMinutes: selectedService.durationMinutes
            ),
            nextFreeDay: nil,
            load: store.appointmentCount(forSpecialist: booking.specialistName, on: selectedDay)
        )
    }

    /// Opens on the master this client already goes to here — once, and only when they
    /// did not arrive with a choice already made.
    private func applyUsualSpecialistIfNeeded() {
        guard !didApplyUsualSpecialist else { return }
        didApplyUsualSpecialist = true
        guard flow.specialistName == nil, selectedSpecialistName == nil else { return }
        guard let usual = store.usualSpecialistName(at: flow.provider),
              options.option(named: usual) != nil else { return }
        selectedSpecialistName = usual
    }

    // MARK: - Sections

    private var summary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selectedService.name)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Palette.ink)
            Text("\(selectedService.durationText) · \(selectedService.priceText)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Palette.inkSoft)
            Divider().overlay(Palette.hairline)
            Label("\(flow.provider.name) · \(flow.provider.address)", systemImage: "mappin.and.ellipse")
                .font(.footnote)
                .foregroundStyle(Palette.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var servicePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Paslauga")
            VStack(spacing: 0) {
                ForEach(flow.provider.services) { service in
                    Button {
                        selectedService = service
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(service.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Palette.ink)
                                Text("\(service.durationText) · \(service.priceText)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(Palette.inkSoft)
                            }
                            Spacer(minLength: 8)
                            Image(systemName: selectedService.id == service.id ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(selectedService.id == service.id ? Palette.forest : Palette.hairline)
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    if service.id != flow.provider.services.last?.id {
                        Divider().overlay(Palette.hairline)
                    }
                }
            }
            .cardSurface(padding: 16)
        }
    }

    private var dayPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Pasirink dieną", accessory: selectedDay.relativeDayText)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(days, id: \.timeIntervalSince1970) { day in
                        dayChip(day)
                    }
                }
            }
            .contentMargins(.horizontal, 2, for: .scrollContent)
        }
    }

    private func dayChip(_ day: Date) -> some View {
        let isSelected = AppDate.isSameDay(day, selectedDay)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedDay = day
            }
        } label: {
            VStack(spacing: 4) {
                Text(day.weekdayShortText)
                    .font(.caption2.weight(.medium))
                Text(day.dayNumberText)
                    .font(.title3.weight(.semibold).monospacedDigit())
            }
            .frame(width: 54, height: 66)
            .foregroundStyle(isSelected ? Palette.bone : Palette.ink)
            .background(isSelected ? Palette.forest : Palette.surface, in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Palette.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.dayText)
    }

    private var timeGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Laisvi laikai", accessory: slots.isEmpty ? nil : "\(slots.count)")
            if slots.isEmpty {
                emptyDay
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(slots, id: \.timeIntervalSince1970) { slot in
                        slotButton(slot)
                    }
                }
            }
        }
    }

    /// A closed day says whose day is closed, and offers the way out that exists: the
    /// next day this master is free, or everyone else who could do it today.
    private var emptyDay: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock.badge.questionmark")
                .font(.title2)
                .foregroundStyle(Palette.inkSoft)
            Text(selectedSpecialistName == nil
                 ? "Šią dieną laisvų laikų nėra"
                 : "\(assignedSpecialist?.firstName ?? "Meistras") šią dieną užimtas")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)

            if let name = selectedSpecialistName,
               let nextFree = options.option(named: name)?.nextFreeDay {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        selectedDay = AppDate.startOfDay(nextFree)
                    }
                } label: {
                    Text("Rodyti \(nextFree.relativeDayText.lowercased())")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.forest)
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
            } else if selectedSpecialistName != nil, !options.combinedSlots.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        selectedSpecialistName = nil
                    }
                } label: {
                    Text("Rodyti kitų meistrų laikus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.forest)
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
            } else {
                Text("Pabandyk kitą dieną — laikai atsinaujina, kai kas nors perkelia vizitą.")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .cardSurface()
    }

    private func slotButton(_ slot: Date) -> some View {
        let isSelected = selectedSlot == slot
        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                selectedSlot = slot
            }
        } label: {
            Text(slot.timeText)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .frame(maxWidth: .infinity, minHeight: 46)
                .foregroundStyle(isSelected ? Palette.ink : Palette.ink.opacity(0.85))
                .background(isSelected ? Palette.marigold : Palette.surface, in: .rect(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color.clear : Palette.hairline, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    private var reassurance: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Nemokamas atšaukimas iki 24 val. prieš vizitą", systemImage: "shield.lefthalf.filled")
            Label("Šiandien mokėti nereikia", systemImage: "creditcard")
        }
        .font(.footnote)
        .foregroundStyle(Palette.inkSoft)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var confirmBar: some View {
        VStack(spacing: 8) {
            if let selectedSlot {
                // Naming the person before the tap is the whole point of choosing one —
                // including when the client left it to the salon.
                Text("\(selectedSlot.relativeDayTimeText) · \(assignedSpecialist?.name ?? flow.provider.specialistName)")
                    .font(.footnote)
                    .foregroundStyle(Palette.inkSoft)
                    .lineLimit(1)
            }
            Button {
                confirm()
            } label: {
                Text(isRescheduling
                     ? "Perkelti vizitą"
                     : "Patvirtinti rezervaciją · \(selectedService.priceText)")
            }
            .buttonStyle(MarigoldButtonStyle(isDisabled: selectedSlot == nil))
            .disabled(selectedSlot == nil)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private func confirm() {
        guard let selectedSlot else { return }
        if let existing = flow.rescheduling {
            store.reschedule(existing, to: selectedSlot)
            if let updated = store.booking(with: existing.id) {
                onCompleted(updated)
            }
        } else {
            let booking = store.book(
                provider: flow.provider,
                service: selectedService,
                at: selectedSlot,
                clientName: flow.clientName,
                specialistName: assignedSpecialist?.name
            )
            onCompleted(booking)
        }
        dismiss()
    }
}
