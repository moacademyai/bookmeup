import SwiftUI

/// The first screen of BookMeUp.
///
/// It has exactly one job: let the client say what they need. So it holds a greeting, the
/// question, the assistant box and three shortcuts — and nothing else. No next visit, no
/// recommendations, no favorites feed. Appointments belong to Vizitai and browsing belongs
/// to Aplink mane; repeating them here would only make the one thing this screen is for
/// harder to find.
///
/// The empty space is the design. It is what tells someone, before they read a word, that
/// they are not expected to search.
struct AssistantHomeView: View {
    @Environment(BookMeUpStore.self) private var store
    @Environment(AssistantConversation.self) private var conversation
    @Environment(DiscoveryLocationService.self) private var location

    @State private var path = NavigationPath()
    @State private var draft = ""
    /// Owned here so a tap on the empty space around the box dismisses the keyboard.
    @FocusState private var isInputFocused: Bool

    private var prompts: [String] {
        AssistantPromptLibrary.prompts(for: store.signedInExperienceProfile).map(\.text)
    }

    var body: some View {
        NavigationStack(path: $path) {
            // Scrollable so the keyboard can be swiped away and so the layout still
            // fits once the keyboard takes half the screen. The minimum height keeps
            // the spacers doing exactly what they did before.
            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        greetingBlock
                            .padding(.horizontal, 24)
                            .padding(.top, 28)

                        Spacer(minLength: 28)

                        AssistantHeroBox(text: $draft, prompts: prompts, isFocused: $isInputFocused) {
                            send(draft)
                            draft = ""
                        }
                        .padding(.horizontal, 20)

                        AssistantQuickActionsRow { action in
                            send(action.request)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                        Spacer(minLength: 24)
                    }
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .leading)
                    .contentShape(.rect)
                    // A tap on anything that is not the box or a button puts the
                    // keyboard away, the way every native screen behaves.
                    .onTapGesture { isInputFocused = false }
                }
                .scrollDismissesKeyboard(.interactively)
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
            }
            .background(Palette.bone)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AssistantRoute.self) { _ in
                AssistantConversationView()
            }
            .navigationDestination(for: Booking.self) { booking in
                ClientBookingDetailView(bookingID: booking.id)
            }
            .navigationDestination(for: Provider.self) { provider in
                ProviderDetailView(provider: provider)
            }
        }
        .tint(Palette.forest)
    }

    private var greetingBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Kuo galiu padėti šiandien?")
                .font(.title3)
                .foregroundStyle(Palette.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greeting: String {
        let hour = AppDate.calendar.component(.hour, from: Date())
        let name = store.signedInClient?.firstName ?? store.clientName
        return switch hour {
        case 5..<12: "Labas rytas, \(name)"
        case 12..<18: "Laba diena, \(name)"
        default: "Labas vakaras, \(name)"
        }
    }

    /// Asking something is what turns this screen into a conversation — never before.
    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        path.append(AssistantRoute.conversation)
        let context = AssistantContextBuilder.make(store: store, location: location)
        Task { await conversation.send(trimmed, context: context) }
    }
}

/// The only route the assistant home pushes on its own.
nonisolated enum AssistantRoute: Hashable {
    case conversation
}
