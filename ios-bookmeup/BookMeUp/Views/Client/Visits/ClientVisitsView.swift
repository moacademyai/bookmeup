import SwiftUI

/// „Vizitai“ — everything the client booked and everywhere they have been.
///
/// Three honest states rather than a feed: what is coming, what happened, and what was
/// called off. The actions follow the state strictly — an upcoming visit can be moved or
/// cancelled, a past one can be repeated or reviewed — so nothing here can quietly create
/// a second appointment the client did not intend.
struct ClientVisitsView: View {
    @Environment(BookMeUpStore.self) private var store

    @State private var path = NavigationPath()
    @State private var scope: Scope = .upcoming
    @State private var bookingFlow: BookingFlow?
    @State private var reviewCandidate: Booking?
    @State private var cancelCandidate: Booking?
    @State private var toast: String?

    private enum Scope: String, CaseIterable, Identifiable {
        case upcoming
        case past
        case cancelled

        var id: String { rawValue }

        var title: String {
            switch self {
            case .upcoming: "Ateinantys"
            case .past: "Buvę"
            case .cancelled: "Atšaukti"
            }
        }
    }

    private var bookings: [Booking] {
        switch scope {
        case .upcoming: store.upcomingClientBookings
        case .past: store.pastClientVisits
        case .cancelled: store.cancelledClientBookings
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 12) {
                    picker

                    if bookings.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(bookings) { booking in
                                card(booking)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 28)
            }
            .background(Palette.bone)
            .scrollIndicators(.hidden)
            .navigationTitle("Vizitai")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Palette.bone, for: .navigationBar)
            .navigationDestination(for: Booking.self) { booking in
                ClientBookingDetailView(bookingID: booking.id)
            }
            .navigationDestination(for: Provider.self) { provider in
                ProviderDetailView(provider: provider)
            }
        }
        .tint(Palette.forest)
        .sheet(item: $bookingFlow) { flow in
            BookingSheet(flow: flow) { booking in
                toast = flow.rescheduling == nil
                    ? "Rezervacija patvirtinta · \(booking.start.relativeDayTimeText)"
                    : "Vizitas perkeltas · \(booking.start.relativeDayTimeText)"
            }
            .environment(store)
        }
        .sheet(item: $reviewCandidate) { booking in
            LeaveReviewSheet(booking: booking) { _ in
                toast = "Ačiū už atsiliepimą"
            }
            .environment(store)
        }
        .confirmationDialog(
            "Atšaukti šį vizitą?",
            isPresented: Binding(
                get: { cancelCandidate != nil },
                set: { if !$0 { cancelCandidate = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Atšaukti vizitą", role: .destructive) {
                if let cancelCandidate {
                    store.cancel(cancelCandidate)
                    toast = "Vizitas atšauktas"
                }
                cancelCandidate = nil
            }
            Button("Palikti", role: .cancel) { cancelCandidate = nil }
        } message: {
            Text("Atšaukti nemokamai gali iki 24 val. prieš vizitą.")
        }
        .overlay(alignment: .bottom) {
            if let toast {
                ToastView(message: toast)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(2.6))
                        withAnimation(.easeOut(duration: 0.25)) { self.toast = nil }
                    }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: toast)
    }

    private var picker: some View {
        Picker("Vizitai", selection: $scope) {
            ForEach(Scope.allCases) { scope in
                Text(scope.title).tag(scope)
            }
        }
        .pickerStyle(.segmented)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func card(_ booking: Booking) -> some View {
        switch scope {
        case .upcoming:
            AppointmentCard(
                booking: booking,
                style: .upcoming,
                onOpen: { path.append(booking) },
                onReschedule: { reschedule(booking) },
                onCancel: { cancelCandidate = booking }
            )
        case .past:
            AppointmentCard(
                booking: booking,
                style: .past,
                onOpen: { path.append(booking) },
                onRebook: { rebook(booking) },
                onReview: store.canReview(booking) ? { reviewCandidate = booking } : nil
            )
        case .cancelled:
            AppointmentCard(
                booking: booking,
                style: .cancelled,
                onOpen: { path.append(booking) },
                onRebook: { rebook(booking) }
            )
        }
    }

    // MARK: - Empty states

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: emptySymbol)
                .font(.largeTitle)
                .foregroundStyle(Palette.forest.opacity(0.7))
            Text(emptyMessage)
                .font(.subheadline)
                .foregroundStyle(Palette.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .padding(.horizontal, 16)
        .cardSurface(padding: 16)
        .padding(.top, 20)
    }

    private var emptySymbol: String {
        switch scope {
        case .upcoming: "calendar"
        case .past: "clock.arrow.circlepath"
        case .cancelled: "xmark.circle"
        }
    }

    private var emptyMessage: String {
        switch scope {
        case .upcoming: "Kol kas neturite artėjančių vizitų."
        case .past: "Įvykę vizitai atsiras čia."
        case .cancelled: "Atšauktų vizitų nėra."
        }
    }

    // MARK: - Actions

    private func reschedule(_ booking: Booking) {
        guard let provider = store.provider(with: booking.providerID) else { return }
        bookingFlow = BookingFlow(provider: provider, rescheduling: booking)
    }

    /// Always a brand-new booking against today's prices and today's availability. A
    /// cancelled appointment is never silently brought back to life.
    private func rebook(_ booking: Booking) {
        guard let provider = store.provider(with: booking.providerID) else { return }
        bookingFlow = BookingFlow(
            provider: provider,
            service: provider.services.first { $0.name == booking.serviceName }
        )
    }
}
