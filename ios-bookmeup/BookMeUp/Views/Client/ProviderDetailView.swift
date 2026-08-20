import SwiftUI

/// The business profile.
///
/// A premium marketplace page, kept deliberately short: photographs, who they are, how to
/// reach them, what people said, what they do, and one action. Everything a client needs
/// to decide — and nothing shown only because the data exists.
struct ProviderDetailView: View {
    let provider: Provider

    @Environment(BookMeUpStore.self) private var store
    @Environment(DiscoveryLocationService.self) private var location
    @Environment(\.openURL) private var openURL

    @State private var selectedService: ServiceOffering?
    @State private var bookingFlow: BookingFlow?
    @State private var showsAllHours = false
    @State private var toast: String?

    private var activeService: ServiceOffering {
        selectedService ?? provider.services[0]
    }

    private var reviews: [ProviderReview] {
        store.reviews(for: provider.id)
    }

    /// The people who work here. Shown only when there is a real choice to make.
    private var specialists: [TeamMember] {
        let roster = store.specialists(at: provider)
        return roster.count > 1 ? roster : []
    }

    private var distanceText: String? {
        ClientPersonalization
            .distance(to: provider, from: location.distanceReference)
            .map(DistanceText.short)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                BusinessGallery(photoNames: provider.gallery)
                header
                about
                information
                if !specialists.isEmpty {
                    team
                }
                reviewsSection
                services
            }
            .padding(.bottom, 28)
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle(provider.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.toggleFavorite(provider)
                } label: {
                    Image(systemName: store.isFavorite(provider) ? "heart.fill" : "heart")
                        .foregroundStyle(store.isFavorite(provider) ? Palette.terracotta : Palette.forest)
                }
                .accessibilityLabel(store.isFavorite(provider) ? "Pašalinti iš mėgstamiausių" : "Įtraukti į mėgstamiausius")
            }
        }
        .safeAreaInset(edge: .bottom) { bookBar }
        .sheet(item: $bookingFlow) { flow in
            BookingSheet(flow: flow) { booking in
                toast = "Rezervacija patvirtinta · \(booking.start.relativeDayTimeText)"
            }
            .environment(store)
        }
        .overlay(alignment: .bottom) {
            if let toast {
                ToastView(message: toast)
                    .padding(.bottom, 96)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(2.6))
                        withAnimation(.easeOut(duration: 0.25)) { self.toast = nil }
                    }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: toast)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(provider.name)
                .font(.title.weight(.bold))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Palette.marigold)
                Text(provider.ratingText)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Palette.ink)
                if let count = provider.reviewCountText {
                    Text("· \(count)")
                        .font(.subheadline)
                        .foregroundStyle(Palette.inkSoft)
                }
            }

            HStack(spacing: 8) {
                Label(provider.category.title, systemImage: provider.category.symbolName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Palette.forest)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Palette.eucalyptus.opacity(0.45), in: .capsule)

                Text(provider.craft)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Palette.inkSoft)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Palette.surface, in: .capsule)
                    .overlay { Capsule().stroke(Palette.hairline, lineWidth: 1) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    private var about: some View {
        Text(provider.about)
            .font(.subheadline)
            .foregroundStyle(Palette.inkSoft)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
    }

    // MARK: - Information

    private var information: some View {
        VStack(spacing: 0) {
            addressRow
            if let phone = provider.phone {
                Divider().overlay(Palette.hairline)
                phoneRow(phone)
            }
            if !provider.openingHours.isEmpty {
                Divider().overlay(Palette.hairline)
                hoursRow
            }
        }
        .cardSurface(padding: 16)
        .padding(.horizontal, 20)
    }

    private var addressRow: some View {
        Button {
            openInMaps()
        } label: {
            infoRow(
                icon: "mappin.and.ellipse",
                title: provider.address,
                detail: [distanceText, provider.district].compactMap { $0 }.joined(separator: " · "),
                accessory: "arrow.triangle.turn.up.right.circle"
            )
        }
        .buttonStyle(.plain)
    }

    private func phoneRow(_ phone: String) -> some View {
        Button {
            call(phone)
        } label: {
            infoRow(icon: "phone", title: phone, detail: "Skambinti verslui", accessory: "phone.circle")
        }
        .buttonStyle(.plain)
    }

    private var hoursRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    showsAllHours.toggle()
                }
            } label: {
                infoRow(
                    icon: "clock",
                    title: provider.openingHours.statusText() ?? "Darbo laikas",
                    detail: provider.openingHours.isOpenNow ? "Dirba dabar" : "Savaitės grafikas",
                    accessory: showsAllHours ? "chevron.up" : "chevron.down"
                )
            }
            .buttonStyle(.plain)

            if showsAllHours {
                VStack(spacing: 6) {
                    ForEach(provider.openingHours) { entry in
                        HStack {
                            Text(entry.weekdayText)
                                .font(.caption)
                                .foregroundStyle(Palette.inkSoft)
                            Spacer(minLength: 8)
                            Text(entry.rangeText)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(entry.isClosed ? Palette.inkSoft : Palette.ink)
                        }
                    }
                }
                .padding(.leading, 46)
                .padding(.bottom, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func infoRow(icon: String, title: String, detail: String, accessory: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(Palette.forest)
                .frame(width: 34, height: 34)
                .background(Palette.eucalyptus.opacity(0.4), in: .rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.leading)
                if !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Palette.inkSoft)
                }
            }
            Spacer(minLength: 4)
            Image(systemName: accessory)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.inkSoft)
        }
        .frame(minHeight: 44)
        .padding(.vertical, 8)
        .contentShape(.rect)
    }

    // MARK: - Team

    /// Who works here, and a direct way to book the one you trust.
    ///
    /// A client of this trade follows a person, not a salon, so choosing the master is
    /// offered here as an entry point of its own — not buried inside the booking sheet.
    private var team: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Specialistai", accessory: "\(specialists.count)")
            VStack(spacing: 0) {
                ForEach(specialists) { member in
                    Button {
                        bookingFlow = BookingFlow(
                            provider: provider,
                            service: member.canPerform(activeService) ? activeService : nil,
                            specialistName: member.name
                        )
                    } label: {
                        specialistRow(member)
                    }
                    .buttonStyle(.plain)
                    if member.id != specialists.last?.id {
                        Divider().overlay(Palette.hairline)
                    }
                }
            }
            .cardSurface(padding: 16)
        }
        .padding(.horizontal, 20)
    }

    private func specialistRow(_ member: TeamMember) -> some View {
        HStack(spacing: 12) {
            SpecialistAvatar(member: member, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(member.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                HStack(spacing: 5) {
                    if let rating = member.ratingText {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Palette.marigold)
                        Text(rating)
                            .font(.caption.weight(.medium).monospacedDigit())
                            .foregroundStyle(Palette.ink)
                    }
                    Text([member.craft, member.experienceText].compactMap { $0 }.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(Palette.inkSoft)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            Text("Registruotis")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.forest)
        }
        .frame(minHeight: 44)
        .padding(.vertical, 8)
        .contentShape(.rect)
    }

    // MARK: - Reviews

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Atsiliepimai")

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    VStack(spacing: 2) {
                        Text(provider.ratingText)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.ink)
                        StarRatingView(rating: provider.rating, size: 11)
                    }
                    if let count = provider.reviewCountText {
                        Text(count)
                            .font(.subheadline)
                            .foregroundStyle(Palette.inkSoft)
                    }
                    Spacer(minLength: 0)
                }

                if let latest = reviews.first {
                    Divider().overlay(Palette.hairline)
                    ReviewRow(review: latest)
                }

                if !reviews.isEmpty {
                    NavigationLink {
                        BusinessReviewsView(provider: provider)
                    } label: {
                        Text("Peržiūrėti visus atsiliepimus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Palette.forest)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
            .cardSurface(padding: 16)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Services

    private var services: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Paslaugos")
            VStack(spacing: 0) {
                ForEach(provider.services) { service in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedService = service
                        }
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(service.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Palette.ink)
                                Text("\(service.priceText) · \(service.durationText)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(Palette.inkSoft)
                            }
                            Spacer(minLength: 8)
                            Image(systemName: activeService.id == service.id ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(activeService.id == service.id ? Palette.forest : Palette.hairline)
                        }
                        .frame(minHeight: 44)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    if service.id != provider.services.last?.id {
                        Divider().overlay(Palette.hairline)
                    }
                }
            }
            .cardSurface()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Booking

    private var bookBar: some View {
        VStack(spacing: 6) {
            Button {
                bookingFlow = BookingFlow(provider: provider, service: activeService)
            } label: {
                Text("Registruotis")
            }
            .buttonStyle(MarigoldButtonStyle())

            Text("\(activeService.name) · \(activeService.priceText)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(Palette.inkSoft)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.bar)
    }

    // MARK: - Actions

    private func call(_ phone: String) {
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel://\(digits)") else { return }
        openURL(url)
    }

    /// Hands the address to the system maps app, which is where navigation belongs.
    private func openInMaps() {
        let query = provider.location.geocodingQuery
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "http://maps.apple.com/?q=\(query)") else { return }
        openURL(url)
    }
}
