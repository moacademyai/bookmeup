import SwiftUI

/// Full information about one of the client's own visits.
///
/// The actions offered depend strictly on where the visit sits in time. An appointment
/// that has not happened yet offers exactly two things — move it, or call it off — and
/// deliberately never offers to book it again: that is how duplicate appointments get
/// created by accident.
struct ClientBookingDetailView: View {
    let bookingID: UUID

    @Environment(BookMeUpStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var bookingFlow: BookingFlow?
    @State private var reviewCandidate: Booking?
    @State private var showCancelDialog = false

    private var booking: Booking? { store.booking(with: bookingID) }

    var body: some View {
        ScrollView {
            if let booking {
                VStack(alignment: .leading, spacing: 22) {
                    header(booking)
                    details(booking)
                    preparation(booking)
                    actions(booking)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            } else {
                ContentUnavailableView("Rezervacija nerasta", systemImage: "calendar.badge.exclamationmark")
                    .padding(.top, 60)
            }
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle("Vizito informacija")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $bookingFlow) { flow in
            BookingSheet(flow: flow).environment(store)
        }
        .sheet(item: $reviewCandidate) { booking in
            LeaveReviewSheet(booking: booking).environment(store)
        }
        .confirmationDialog("Atšaukti šį vizitą?", isPresented: $showCancelDialog, titleVisibility: .visible) {
            Button("Atšaukti vizitą", role: .destructive) {
                if let booking { store.cancel(booking) }
                dismiss()
            }
            Button("Palikti", role: .cancel) { }
        } message: {
            Text("Atšaukti nemokamai gali iki 24 val. prieš vizitą.")
        }
    }

    private func header(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            AssetImage(name: booking.imageName, height: 180, cornerRadius: 20)
            VStack(alignment: .leading, spacing: 8) {
                StatusChip(status: booking.status)
                Text(booking.start.relativeDayTimeText)
                    .font(.title.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
                Text("\(booking.specialistName) · \(booking.providerName)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 16)
        .padding(.top, 8)
    }

    private func details(_ booking: Booking) -> some View {
        VStack(spacing: 0) {
            detailRow(icon: "scissors", title: "Paslauga", value: booking.serviceName)
            Divider().overlay(Palette.hairline)
            detailRow(icon: "clock", title: "Trukmė", value: booking.durationText)
            Divider().overlay(Palette.hairline)
            detailRow(icon: "tag", title: "Kaina", value: booking.price.asEuro)
            Divider().overlay(Palette.hairline)
            detailRow(icon: "mappin.and.ellipse", title: "Vieta", value: "\(booking.providerName) · \(booking.address)")
        }
        .cardSurface(padding: 16)
    }

    /// Only shown when there is something real to say.
    ///
    /// The cancellation policy applies to every booking, so it always belongs here. The
    /// rest comes from the appointment itself — a note the client left, the previous
    /// visit — and until businesses can publish their own preparation instructions,
    /// nothing generic is invented to fill the space.
    @ViewBuilder
    private func preparation(_ booking: Booking) -> some View {
        let lines = preparationLines(booking)
        if !lines.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Verta žinoti")
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(lines, id: \.text) { line in
                        Label(line.text, systemImage: line.symbol)
                    }
                }
                .font(.footnote)
                .foregroundStyle(Palette.inkSoft)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardSurface()
            }
        }
    }

    private func preparationLines(_ booking: Booking) -> [(text: String, symbol: String)] {
        var lines: [(String, String)] = []
        if booking.status.isActive && booking.end > Date() {
            lines.append(("Nemokamas atšaukimas iki 24 val. prieš vizitą", "shield.lefthalf.filled"))
        }
        if !booking.clientNote.isEmpty {
            lines.append((booking.clientNote, "text.bubble"))
        }
        if let previous = booking.previousVisit {
            lines.append(("Paskutinis vizitas · \(previous.dayText)", "clock.arrow.circlepath"))
        }
        return lines.map { (text: $0.0, symbol: $0.1) }
    }

    /// Upcoming: move or cancel. Past: repeat or review. Cancelled: start a new booking.
    @ViewBuilder
    private func actions(_ booking: Booking) -> some View {
        if booking.status.isActive && booking.end > Date() {
            VStack(spacing: 10) {
                Button {
                    reschedule(booking)
                } label: {
                    Label("Pakeisti laiką", systemImage: "calendar")
                }
                .buttonStyle(MarigoldButtonStyle())

                Button {
                    showCancelDialog = true
                } label: {
                    Label("Atšaukti rezervaciją", systemImage: "xmark.circle")
                }
                .buttonStyle(QuietButtonStyle(tint: Palette.terracotta))
            }
        } else {
            VStack(spacing: 10) {
                if store.canReview(booking) {
                    Button {
                        reviewCandidate = booking
                    } label: {
                        Label("Palikti atsiliepimą", systemImage: "star")
                    }
                    .buttonStyle(MarigoldButtonStyle())
                }

                Button {
                    rebook(booking)
                } label: {
                    Label("Rezervuoti dar kartą", systemImage: "arrow.trianglehead.clockwise")
                }
                .buttonStyle(QuietButtonStyle(tint: Palette.forest))
            }
        }
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(Palette.forest)
                .frame(width: 34, height: 34)
                .background(Palette.eucalyptus.opacity(0.4), in: .rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Palette.ink)
            }
            Spacer(minLength: 4)
        }
        .padding(.vertical, 10)
    }

    private func reschedule(_ booking: Booking) {
        guard let provider = store.provider(with: booking.providerID) else { return }
        bookingFlow = BookingFlow(provider: provider, rescheduling: booking)
    }

    /// A new booking, at today's prices and today's availability.
    private func rebook(_ booking: Booking) {
        guard let provider = store.provider(with: booking.providerID) else { return }
        bookingFlow = BookingFlow(
            provider: provider,
            service: provider.services.first { $0.name == booking.serviceName }
        )
    }
}
