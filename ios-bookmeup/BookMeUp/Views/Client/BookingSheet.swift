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
}

/// Focused native sheet for choosing a service, a day and a time.
struct BookingSheet: View {
    let flow: BookingFlow
    var onCompleted: (Booking) -> Void = { _ in }

    @Environment(BookMeUpStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedService: ServiceOffering
    @State private var selectedDay: Date
    @State private var selectedSlot: Date?

    init(flow: BookingFlow, onCompleted: @escaping (Booking) -> Void = { _ in }) {
        self.flow = flow
        self.onCompleted = onCompleted
        let service = flow.service
            ?? flow.provider.services.first { $0.name == flow.rescheduling?.serviceName }
            ?? flow.provider.services[0]
        _selectedService = State(initialValue: service)
        _selectedDay = State(initialValue: AppDate.startOfDay(flow.preselectedSlot ?? flow.provider.nextSlot))
        _selectedSlot = State(initialValue: flow.preselectedSlot)
    }

    private var days: [Date] {
        (0..<14).map { AppDate.time(9, 0, dayOffset: $0) }
    }

    private var slots: [Date] {
        store.availableSlots(
            for: flow.provider,
            on: selectedDay,
            durationMinutes: selectedService.durationMinutes
        )
    }

    private var isRescheduling: Bool { flow.rescheduling != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    summary
                    if !isRescheduling && flow.provider.services.count > 1 {
                        servicePicker
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
        .onChange(of: selectedDay) { _, _ in selectedSlot = nil }
        .onChange(of: selectedService) { _, _ in selectedSlot = nil }
    }

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
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.title2)
                        .foregroundStyle(Palette.inkSoft)
                    Text("Šią dieną laisvų laikų nėra")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Palette.ink)
                    Text("Pabandyk kitą dieną — laikai atsinaujina, kai kas nors perkelia vizitą.")
                        .font(.caption)
                        .foregroundStyle(Palette.inkSoft)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .cardSurface()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(slots, id: \.timeIntervalSince1970) { slot in
                        slotButton(slot)
                    }
                }
            }
        }
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
                Text("\(selectedSlot.relativeDayTimeText) · \(flow.provider.specialistName)")
                    .font(.footnote)
                    .foregroundStyle(Palette.inkSoft)
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
                clientName: flow.clientName
            )
            onCompleted(booking)
        }
        dismiss()
    }
}
