import SwiftUI

/// Whose clients the list shows.
///
/// The same list serves the specialist and the owner — one client module, one search,
/// one create flow. Only the set of records differs, and that is a permission question.
nonisolated enum ClientListScope {
    /// People this specialist works with.
    case specialist
    /// The whole business base.
    case business
}

/// The client base: one always-reachable search field and a list that filters while
/// typing. Every row is a real client record from the store.
struct ClientsListView: View {
    /// The workspace pushes this view onto a stack that hides the tab bar;
    /// as a root tab it must keep the tab bar visible.
    var hidesTabBar: Bool = true
    var scope: ClientListScope = .specialist
    /// A pushed screen needs a title to say where it is. As a root tab the selected
    /// tab already says "Klientai", and a large title would only push the search
    /// field a screenful down.
    var showsLargeTitle: Bool = true

    @Environment(BookMeUpStore.self) private var store
    @State private var query = ""
    @State private var showNewClientSheet = false
    /// Set while the sheet is closing, then pushed once it is gone.
    @State private var clientToOpen: Client?
    @State private var openedClient: Client?
    @FocusState private var isSearchFocused: Bool

    private var results: [Client] {
        switch scope {
        case .specialist: store.specialistClients(matching: query)
        case .business: store.businessClients(matching: query)
        }
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                countLine

                if results.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, client in
                        NavigationLink(value: client) {
                            clientRow(client)
                        }
                        .buttonStyle(.plain)

                        if index < results.count - 1 {
                            Divider()
                                .overlay(Palette.hairline)
                                .padding(.leading, 60)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 2)
            .padding(.bottom, 28)
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .safeAreaInset(edge: .top, spacing: 0) { searchHeader }
        .sheet(isPresented: $showNewClientSheet) {
            if let client = clientToOpen {
                clientToOpen = nil
                openedClient = client
            }
        } content: {
            NewClientSheet { client in
                clientToOpen = client
            }
            .environment(store)
        }
        .navigationDestination(item: $openedClient) { client in
            ClientProfileView(client: client)
        }
        .navigationTitle(showsLargeTitle ? "Klientai" : "")
        .navigationBarTitleDisplayMode(showsLargeTitle ? .large : .inline)
        .toolbar(showsLargeTitle ? .visible : .hidden, for: .navigationBar)
        .toolbar(hidesTabBar ? .hidden : .visible, for: .tabBar)
        .toolbarBackground(Palette.bone, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    // MARK: - Search

    /// Search sits at the very top of the screen, where a thumb already is. The
    /// create action is next to it rather than under it, so the list starts higher.
    private var searchHeader: some View {
        HStack(spacing: 10) {
            searchBar
            newClientButton
        }
        .padding(.horizontal, 20)
        .padding(.top, showsLargeTitle ? 0 : 6)
        .padding(.bottom, 10)
        .background(Palette.bone)
    }

    private var newClientButton: some View {
        Button {
            isSearchFocused = false
            showNewClientSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.body.weight(.semibold))
                .foregroundStyle(Palette.ink)
                .frame(width: 48, height: 48)
                .background(Palette.marigold, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Naujas klientas")
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.semibold))
                .foregroundStyle(Palette.inkSoft)

            // The search itself is forgiving — "Kipras 948" finds a name and the last
            // digits of a number — but a placeholder is not the place to teach tricks.
            TextField("Vardas, pavardė arba tel. nr.", text: $query)
                .font(.body)
                .foregroundStyle(Palette.ink)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isSearchFocused)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(Palette.inkSoft.opacity(0.7))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Išvalyti paiešką")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(Palette.surface, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSearchFocused ? Palette.forest.opacity(0.45) : Palette.hairline, lineWidth: 1)
        }
        .animation(.easeOut(duration: 0.18), value: isSearchFocused)
    }

    private var countLine: some View {
        HStack {
            Text(
                trimmedQuery.isEmpty
                    ? "\(results.count) \(LithuanianPlural.client(results.count))"
                    : "Rasta: \(results.count)"
            )
            .font(.caption)
            .foregroundStyle(Palette.inkSoft)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 6)
    }

    private var emptyState: some View {
        Text("Klientų nerasta.")
            .font(.subheadline)
            .foregroundStyle(Palette.inkSoft)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 32)
    }

    // MARK: - Row

    /// Only what a specialist scans for: who they are, how to reach them, when they
    /// were last in and whether they are coming back. Everything else is one tap away.
    private func clientRow(_ client: Client) -> some View {
        HStack(spacing: 12) {
            InitialsAvatar(name: client.fullName, size: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(client.fullName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                Text(client.hasPhone ? client.phoneDisplay : "Numeris nenurodytas")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Palette.inkSoft)
                    .lineLimit(1)
                Text(historyLine(for: client))
                    .font(.caption2)
                    .foregroundStyle(Palette.inkSoft.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 4)

            // A scheduled return is the one thing worth a spot of colour.
            if let next = store.nextVisit(for: client) {
                Text(next.start.relativeDayTimeText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.ink.opacity(0.8))
                    .lineLimit(1)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Palette.marigold.opacity(0.22), in: .capsule)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .contentShape(.rect)
    }

    /// "Dar nesilankė" or "Buvo · prieš 23 d." — recency the specialist can act on.
    private func historyLine(for client: Client) -> String {
        guard let last = store.lastVisit(for: client) else { return "Dar nesilankė" }
        return "Buvo · \(last.start.recencyText.lowercasedFirst)"
    }
}

nonisolated extension String {
    var lowercasedFirst: String {
        guard let first else { return self }
        return first.lowercased() + dropFirst()
    }
}
