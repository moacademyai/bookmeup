import SwiftUI

/// Everything the specialist knows about one client, computed from that client's
/// own booking, attendance and note records.
struct ClientProfileView: View {
    let client: Client

    @Environment(BookMeUpStore.self) private var store
    @Environment(\.openURL) private var openURL

    @State private var showMessageSheet = false
    @State private var showBookingSheet = false
    @State private var showHistorySheet = false
    @State private var noteDraft = ""
    @State private var toast: String?
    @FocusState private var isNoteFocused: Bool

    /// Always read the live record so a new note or booking shows up immediately.
    private var current: Client { store.client(with: client.id) ?? client }
    private var overview: ClientOverview { store.overview(for: current) }
    private var upcoming: Booking? { store.nextVisit(for: current) }
    private var history: [Booking] { store.pastVisits(for: current) }
    private var notes: [ClientNote] { store.notes(for: current) }
    private var passportEntries: [BeautyPassportEntry] { store.passportEntries(for: current) }
    private var latestPassport: BeautyPassportEntry? { passportEntries.first }
    private var attendance: [ClientAttendanceEvent] { store.attendance(for: current) }
    /// Read live from the shared store, so the newest answer always wins.
    private var experienceProfile: ClientExperienceProfile? { store.experienceProfile(for: current) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                if let upcoming {
                    upcomingSection(upcoming)
                }
                experienceSection
                overviewSection
                beautyPassportSection
                historySection
                notesSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(current.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: BeautyPassportEntry.self) { entry in
            BeautyPassportDetailView(client: current, entry: entry)
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(Palette.bone, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .sheet(isPresented: $showMessageSheet) {
            MessageClientSheet(clientName: current.fullName, booking: upcoming)
        }
        .sheet(isPresented: $showBookingSheet) {
            AddAppointmentSheet(date: Date(), presetClient: current) { message in
                toast = message
            }
            .environment(store)
        }
        .sheet(isPresented: $showHistorySheet) {
            ClientHistorySheet(clientName: current.fullName, visits: history)
        }
        .overlay(alignment: .bottom) {
            if let toast {
                ToastView(message: toast)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(2.4))
                        withAnimation(.easeOut(duration: 0.25)) { self.toast = nil }
                    }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: toast)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                InitialsAvatar(name: current.fullName, size: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text(current.fullName)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(current.hasPhone ? current.phone : "Numeris nenurodytas")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Palette.inkSoft)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                actionButton(title: "Rašyti", symbol: "bubble.left") {
                    showMessageSheet = true
                }
                actionButton(title: "Skambinti", symbol: "phone", isEnabled: current.callURL != nil) {
                    if let url = current.callURL { openURL(url) }
                }
                actionButton(title: "Rezervuoti", symbol: "calendar.badge.plus") {
                    showBookingSheet = true
                }
            }
        }
        .cardSurface(padding: 16)
    }

    private func actionButton(
        title: String,
        symbol: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.headline)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isEnabled ? Palette.forest : Palette.inkSoft.opacity(0.5))
            .frame(maxWidth: .infinity, minHeight: 62)
            .background(Palette.eucalyptus.opacity(isEnabled ? 0.32 : 0.14), in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .sensoryFeedback(.selection, trigger: showBookingSheet)
    }

    // MARK: - Upcoming

    private func upcomingSection(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Artimiausias vizitas")

            NavigationLink(value: booking) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(booking.start.relativeDayText)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Palette.ink)
                        Text(booking.start.timeText)
                            .font(.title3.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Palette.forest)
                        Spacer(minLength: 4)
                        StatusChip(status: booking.status, compact: true)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        detailLine(symbol: "scissors", text: "\(booking.serviceName) · \(booking.durationText)")
                        detailLine(symbol: "person", text: booking.specialistName)
                    }

                    HStack(spacing: 6) {
                        Text("Rezervacijos informacija")
                            .font(.caption.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(Palette.forest)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardSurface(padding: 16)
            }
            .buttonStyle(.plain)
        }
    }

    private func detailLine(symbol: String, text: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.subheadline)
            .foregroundStyle(Palette.inkSoft)
    }

    // MARK: - Client Experience

    /// What the client chose to share about how they want to be served.
    ///
    /// Deliberately far away from the internal notes at the bottom and from the
    /// attendance record: this section is the client's own voice, the notes are the
    /// team's, and the two must never read as one thing.
    private var experienceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Kliento pasirinkimai")
            ClientExperienceSummaryView(profile: experienceProfile, style: .detailed)
        }
    }

    // MARK: - Overview

    /// Four relationship numbers inside one card rather than four cards.
    ///
    /// The visit count is the only one that leads anywhere — tapping it opens the full
    /// history — so it is the only one drawn as something you can press.
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Kliento apžvalga")

            VStack(spacing: 14) {
                HStack(spacing: 0) {
                    Button {
                        guard !history.isEmpty else { return }
                        showHistorySheet = true
                    } label: {
                        statCell(
                            value: overview.totalVisitsText,
                            caption: "Iš viso vizitų",
                            showsChevron: !history.isEmpty
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(history.isEmpty)

                    cellDivider

                    statCell(
                        value: overview.averageVisitsPerMonthText,
                        caption: "Vidutiniškai per mėn.",
                        showsChevron: false
                    )
                }

                Divider().overlay(Palette.hairline)

                HStack(spacing: 0) {
                    statCell(
                        value: overview.sinceLastVisitText,
                        caption: "Nuo paskutinio vizito",
                        showsChevron: false
                    )

                    cellDivider

                    statCell(
                        value: overview.averageGapText,
                        caption: "Vidutinis tarpas",
                        showsChevron: false
                    )
                }
            }
            .cardSurface(padding: 16)

            attendanceCard
        }
    }

    private func statCell(value: String, caption: String, showsChevron: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(value)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Palette.inkSoft.opacity(0.6))
                }
            }
            Text(caption)
                .font(.caption)
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }

    private var cellDivider: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(width: 1, height: 32)
            .padding(.horizontal, 12)
    }

    private var attendanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: overview.missedCount == 0 ? "hand.thumbsup" : "exclamationmark.triangle")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(overview.missedCount == 0 ? Palette.forest : Palette.terracotta)
                    .frame(width: 30, height: 30)
                    .background(
                        (overview.missedCount == 0 ? Palette.eucalyptus : Palette.terracotta).opacity(0.22),
                        in: .circle
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vizitų patikimumas")
                        .font(.caption)
                        .foregroundStyle(Palette.inkSoft)
                    Text(overview.attendanceText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let late = overview.lateCancellationText {
                        Text(late)
                            .font(.caption)
                            .foregroundStyle(Palette.inkSoft)
                    }
                    if let approval = overview.approvalNoteText {
                        Text(approval)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Palette.terracotta)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }

            if !attendance.isEmpty {
                Divider().overlay(Palette.hairline)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(attendance) { event in
                        HStack(spacing: 8) {
                            Image(systemName: event.kind.symbolName)
                                .font(.caption2)
                                .foregroundStyle(Palette.terracotta)
                            Text("\(event.kind.title) · \(event.date.dayText)")
                                .font(.caption)
                                .foregroundStyle(Palette.inkSoft)
                            Spacer(minLength: 0)
                            Text(event.serviceName)
                                .font(.caption2)
                                .foregroundStyle(Palette.inkSoft.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 16)
    }

    // MARK: - Beauty Passport

    private var beautyPassportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Grožio pasas",
                accessory: passportEntries.count > 1 ? "\(passportEntries.count)" : nil
            )

            if let latest = latestPassport {
                passportCard(latest)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Grožio paso įrašų dar nėra.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.ink)
                    Text("Įrašas atsiras, kai vizitas bus uždokumentuotas.")
                        .font(.caption)
                        .foregroundStyle(Palette.inkSoft)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardSurface(padding: 16)
            }
        }
    }

    private func passportCard(_ entry: BeautyPassportEntry) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let after = entry.afterPhoto {
                PassportPhotoView(reference: after, height: 200, cornerRadius: 18)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .topLeading) {
                        Text("Po")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Palette.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Palette.bone.opacity(0.9), in: .capsule)
                            .padding(10)
                    }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(entry.date.dayText)
                        .font(.headline)
                        .foregroundStyle(Palette.ink)
                    Spacer(minLength: 4)
                    Text(entry.serviceName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.forest)
                        .lineLimit(1)
                }
                Text(entry.specialistName)
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
            }

            if entry.hasSummary {
                Text(entry.summary)
                    .font(.subheadline)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            NavigationLink(value: entry) {
                Label("Kaip praeįtą kartą", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(QuietButtonStyle(tint: Palette.forest))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 16)
    }

    // MARK: - History

    /// The last few visits, with the rest behind one tap. A profile is a glance, and
    /// a client with forty visits should not turn it into a scroll.
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Vizitų istorija",
                accessory: history.isEmpty ? nil : "\(history.count)"
            )

            if history.isEmpty {
                Text("Vizitų dar nebuvo.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardSurface(padding: 16)
            } else {
                VStack(spacing: 0) {
                    let recent = Array(history.prefix(3))
                    ForEach(Array(recent.enumerated()), id: \.element.id) { index, booking in
                        ClientVisitRow(booking: booking)
                        if index < recent.count - 1 {
                            Divider().overlay(Palette.hairline)
                        }
                    }

                    if history.count > 3 {
                        Divider().overlay(Palette.hairline)
                        Button {
                            showHistorySheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Text("Peržiūrėti visus")
                                    .font(.subheadline.weight(.semibold))
                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.bold))
                                Spacer(minLength: 0)
                            }
                            .foregroundStyle(Palette.forest)
                            .padding(.vertical, 13)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .cardSurface(padding: 16)
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Named apart from "Kliento pasirinkimai" on purpose: that section is the
            // client's own voice, this one is the team's, and they must never blur.
            SectionHeader(title: "Vidinės pastabos", accessory: "Klientas nemato")

            VStack(alignment: .leading, spacing: 12) {
                TextField("Pastaba komandai — klientas jos nemato", text: $noteDraft, axis: .vertical)
                    .font(.subheadline)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2...5)
                    .focused($isNoteFocused)
                    .padding(12)
                    .background(Palette.bone, in: .rect(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14).stroke(Palette.hairline, lineWidth: 1)
                    }

                Button {
                    store.addNote(noteDraft, for: current)
                    noteDraft = ""
                    isNoteFocused = false
                } label: {
                    Label("Pridėti pastabą", systemImage: "plus")
                }
                .buttonStyle(QuietButtonStyle(tint: Palette.forest))
                .disabled(noteDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .sensoryFeedback(.success, trigger: notes.count)
            }
            .cardSurface(padding: 16)

            if notes.isEmpty {
                Text("Pastabų dar nėra. Klientas šių pastabų nemato.")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
                    .padding(.horizontal, 4)
            } else {
                VStack(spacing: 10) {
                    ForEach(notes) { note in
                        noteRow(note)
                    }
                }
            }
        }
    }

    private func noteRow(_ note: ClientNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Text(note.text)
                    .font(.subheadline)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                Button {
                    store.removeNote(note)
                } label: {
                    Image(systemName: "trash")
                        .font(.footnote)
                        .foregroundStyle(Palette.terracotta)
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ištrinti pastabą")
            }
            Text("\(note.author) · \(note.createdAt.dayText)")
                .font(.caption2)
                .foregroundStyle(Palette.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 14, cornerRadius: 18)
    }
}
