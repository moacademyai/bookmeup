import SwiftUI
import MapKit

/// „Aplink mane“ — manual discovery.
///
/// The counterpart to the assistant: this is for the client who would rather look for
/// themselves. It is a map first, because the question here is spatial — what is actually
/// around me — and the assistant already answers the other question.
///
/// The map is the interface, not a backdrop. It never moves on its own: panning, zooming
/// and tapping belong entirely to the client, and the only thing that recentres it is the
/// recentre button or a business they explicitly chose from the list.
///
/// The category order is personalised, but nothing is filtered out. A client whose profile
/// says hair still sees every industry on the platform; their own ones simply come first.
struct NearMeView: View {
    @Environment(BookMeUpStore.self) private var store
    @Environment(DiscoveryLocationService.self) private var location

    @State private var path = NavigationPath()
    @State private var filter: DiscoveryFilter = .forYou
    @State private var mode: BrowseMode = .map
    @State private var sort: DiscoverySort = .forYou
    @State private var selected: Provider?
    @State private var camera: MapCameraPosition = .automatic
    /// The part of the world currently on screen. Businesses are loaded for this, never
    /// for the whole marketplace.
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var bookingFlow: BookingFlow?
    @State private var toast: String?
    @State private var isResolvingLocations = false

    private enum BrowseMode: String, CaseIterable {
        case map
        case list

        var title: String {
            switch self {
            case .map: "Žemėlapis"
            case .list: "Sąrašas"
            }
        }
    }

    private var profile: ClientExperienceProfile? { store.signedInExperienceProfile }

    private var categories: [ServiceCategory] {
        ClientPersonalization.categoryOrder(
            profile: profile,
            history: store.clientVisitHistory,
            providers: store.providers
        )
    }

    /// The businesses drawn on the map: the selected category, inside the visible area.
    private var mapBusinesses: [Provider] {
        guard let visibleRegion else { return [] }
        return store.businesses(in: visibleRegion, category: filter.category)
    }

    private var listBusinesses: [Provider] {
        store.businesses(
            category: filter.category,
            sort: sort,
            profile: profile,
            reference: location.distanceReference
        )
    }

    /// How much a marker can say at the current scale.
    private var markerDetail: BusinessMarker.Detail {
        guard let span = visibleRegion?.span.latitudeDelta else { return .rating }
        if span > 0.28 { return .dot }
        if span > 0.09 || mapBusinesses.count > 14 { return .rating }
        return .full
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 12) {
                CategoryFilterBar(categories: categories, selection: $filter)
                modePicker

                switch mode {
                case .map: mapArea
                case .list: listArea
                }
            }
            .padding(.top, 6)
            .background(Palette.bone)
            // No title: the selected tab already says where the client is, and a
            // centred repeat of it only pushed the categories down a screenful.
            .toolbar(.hidden, for: .navigationBar)
            // The preview sits on the layout frame, which stops at the safe area, so
            // the card and its CTA always clear the tab bar underneath the map.
            .overlay(alignment: .bottom) { previewLayer }
            .navigationDestination(for: Provider.self) { provider in
                ProviderDetailView(provider: provider)
            }
        }
        .tint(Palette.forest)
        .sheet(item: $bookingFlow) { flow in
            BookingSheet(flow: flow) { booking in
                toast = "Rezervacija patvirtinta · \(booking.start.relativeDayTimeText)"
            }
            .environment(store)
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
        .task { await prepare() }
        .onChange(of: filter) { _, _ in selected = nil }
    }

    // MARK: - Mode

    private var modePicker: some View {
        Picker("Rodinys", selection: $mode) {
            ForEach(BrowseMode.allCases, id: \.self) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
    }

    // MARK: - Map

    private var mapArea: some View {
        Map(position: $camera) {
            ForEach(mapBusinesses) { provider in
                if let coordinate = provider.coordinate {
                    Annotation(provider.name, coordinate: coordinate) {
                        Button {
                            select(provider)
                        } label: {
                            BusinessMarker(
                                provider: provider,
                                isSelected: selected?.id == provider.id,
                                detail: markerDetail
                            )
                            // Comfortable target even when the marker collapses to a dot.
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                    .annotationTitles(.hidden)
                }
            }
            UserAnnotation()
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .onMapCameraChange(frequency: .continuous) { context in
            visibleRegion = context.region
        }
        .overlay(alignment: .topTrailing) { recentreButton }
        .overlay(alignment: .top) { loadingBanner }
        .clipShape(.rect(topLeadingRadius: 24, topTrailingRadius: 24))
        .ignoresSafeArea(edges: .bottom)
    }

    /// The standard way back to yourself. Asks for permission the first time it is used
    /// and then never nags again — a client who said no is browsing on purpose.
    private var recentreButton: some View {
        Button {
            recentre()
        } label: {
            Image(systemName: location.hasPreciseLocation ? "location.fill" : "location")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(location.isDenied ? Palette.inkSoft : Palette.forest)
                .frame(width: 44, height: 44)
                .background(Palette.elevated, in: .circle)
                .overlay { Circle().stroke(Palette.hairline, lineWidth: 1) }
                .shadow(color: Color(hex: 0x16241F).opacity(0.14), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 16)
        .padding(.top, 14)
        .accessibilityLabel("Rodyti mano vietą")
    }

    @ViewBuilder
    private var loadingBanner: some View {
        if isResolvingLocations {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small).tint(Palette.forest)
                Text("Ieškoma vietų…")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Palette.elevated.opacity(0.95), in: .capsule)
            .overlay { Capsule().stroke(Palette.hairline, lineWidth: 1) }
            .padding(.top, 14)
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private var previewLayer: some View {
        if mode == .map, let selected {
            BusinessPreviewCard(
                provider: selected,
                distanceMetres: ClientPersonalization.distance(to: selected, from: location.distanceReference),
                isFavorite: store.isFavorite(selected),
                onOpen: { path.append(selected) },
                onBook: { bookingFlow = BookingFlow(provider: selected) },
                onToggleFavorite: { store.toggleFavorite(selected) },
                onDismiss: { withAnimation(.easeOut(duration: 0.2)) { self.selected = nil } }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - List

    private var listArea: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                sortBar
                    .padding(.bottom, 2)

                if listBusinesses.isEmpty {
                    emptyList
                } else {
                    ForEach(listBusinesses) { provider in
                        BusinessRowCard(
                            provider: provider,
                            distanceMetres: ClientPersonalization.distance(to: provider, from: location.distanceReference)
                        ) {
                            path.append(provider)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 2)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    /// Two orders, both deterministic. Anything more specific is a question for the
    /// assistant, not another control here.
    private var sortBar: some View {
        // Each chip is as wide as its own words. Splitting the row into three equal
        // parts is what squeezed "Geriausiai įvertinti" until it clipped.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach([DiscoverySort.forYou, .nearest, .topRated]) { option in
                    let isSelected = sort == option
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { sort = option }
                    } label: {
                        Label(option.title, systemImage: option.symbolName)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(isSelected ? Palette.onPine : Palette.ink)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 38)
                            .background(isSelected ? Palette.pine : Palette.surface, in: .capsule)
                            .overlay {
                                Capsule().stroke(isSelected ? Color.clear : Palette.hairline, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: isSelected)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    }

    private var emptyList: some View {
        VStack(spacing: 8) {
            Text("Šioje srityje nieko neradome")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.ink)
            Text("Pabandykite kitą sritį arba paklauskite Asistento.")
                .font(.caption)
                .foregroundStyle(Palette.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .cardSurface(padding: 16)
    }

    // MARK: - Actions

    private func select(_ provider: Provider) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            selected = selected?.id == provider.id ? nil : provider
        }
    }

    /// Resolves any business that has an address but no coordinates yet, then opens the
    /// map where the client is.
    private func prepare() async {
        camera = .region(
            MKCoordinateRegion(
                center: location.mapCentre,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.06)
            )
        )
        guard store.providers.contains(where: { !$0.location.isResolved }) else { return }
        isResolvingLocations = true
        await store.resolveBusinessLocations()
        withAnimation(.easeOut(duration: 0.25)) { isResolvingLocations = false }
    }

    private func recentre() {
        if location.canAskForPermission {
            location.requestPermission()
            return
        }
        location.refresh()
        withAnimation(.easeInOut(duration: 0.45)) {
            camera = .region(
                MKCoordinateRegion(
                    center: location.mapCentre,
                    span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.04)
                )
            )
        }
    }
}
