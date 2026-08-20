import SwiftUI

/// The conversation with the assistant.
///
/// It reads like a chat, but it answers like a booking agent: every reply that found
/// something renders real options with real times, and the follow-up chips continue the
/// same request instead of starting a new one. The transcript lives above this view, so
/// leaving for the map and coming back does not lose the conversation.
struct AssistantConversationView: View {
    @Environment(BookMeUpStore.self) private var store
    @Environment(AssistantConversation.self) private var conversation
    @Environment(DiscoveryLocationService.self) private var location

    @State private var draft = ""
    @State private var bookingFlow: BookingFlow?
    @State private var openedProvider: Provider?
    @State private var toast: String?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(conversation.messages) { message in
                        messageView(message)
                            .id(message.id)
                    }

                    if conversation.isThinking {
                        thinkingRow.id("thinking")
                    }

                    if let reply = conversation.latestReply, !reply.refinements.isEmpty, !conversation.isThinking {
                        refinements(reply)
                            .id("refinements")
                    }

                    if let notice = conversation.latestReply?.source.notice {
                        sourceNotice(notice)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: conversation.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(conversation.messages.last?.id, anchor: .bottom)
                }
            }
        }
        .background(Palette.bone)
        .navigationTitle("Asistentas")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(Palette.bone, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    conversation.reset()
                } label: {
                    Label("Naujas pokalbis", systemImage: "square.and.pencil")
                }
                .disabled(conversation.isEmpty)
            }
        }
        .safeAreaInset(edge: .bottom) {
            AssistantComposer(text: $draft) {
                send(draft)
                draft = ""
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 6)
            .background(.bar)
        }
        .navigationDestination(item: $openedProvider) { provider in
            ProviderDetailView(provider: provider)
        }
        .sheet(item: $bookingFlow) { flow in
            BookingSheet(flow: flow) { booking in
                toast = "Rezervacija patvirtinta · \(booking.start.relativeDayTimeText)"
            }
            .environment(store)
        }
        .overlay(alignment: .bottom) {
            if let toast {
                ToastView(message: toast)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(2.6))
                        withAnimation(.easeOut(duration: 0.25)) { self.toast = nil }
                    }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: toast)
    }

    // MARK: - Messages

    @ViewBuilder
    private func messageView(_ message: AssistantMessage) -> some View {
        switch message.author {
        case .client:
            HStack {
                Spacer(minLength: 40)
                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(Palette.onPine)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Palette.pine, in: .rect(cornerRadius: 20))
            }
        case .assistant:
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    assistantMark
                    Text(message.text)
                        .font(.subheadline)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }

                if let reply = message.reply {
                    if reply.query.hasAnyConstraint {
                        understanding(reply.query)
                    }
                    ForEach(Array(reply.offers.enumerated()), id: \.element.id) { index, offer in
                        AssistantOfferCardView(
                            offer: offer,
                            isPrimary: index == 0,
                            onOpenProvider: { open(offer.provider) },
                            onBook: { slot in book(offer, at: slot) }
                        )
                    }
                }
            }
        }
    }

    private var assistantMark: some View {
        Image(systemName: "sparkle")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Palette.forest)
            .frame(width: 28, height: 28)
            .background(Palette.eucalyptus.opacity(0.45), in: .circle)
    }

    /// What the assistant took from the request. Visible so a client can immediately see
    /// a misreading instead of wondering why the results look wrong.
    private func understanding(_ query: AssistantQuery) -> some View {
        Label(query.understandingText, systemImage: "checkmark.circle")
            .font(.caption.weight(.medium))
            .foregroundStyle(Palette.forest)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.eucalyptus.opacity(0.28), in: .rect(cornerRadius: 14))
    }

    private var thinkingRow: some View {
        HStack(spacing: 10) {
            assistantMark
            Text("Ieškau…")
                .font(.subheadline)
                .foregroundStyle(Palette.inkSoft)
            ProgressView()
                .controlSize(.small)
                .tint(Palette.forest)
            Spacer(minLength: 0)
        }
    }

    private func refinements(_ reply: AssistantReply) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Patikslinti")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.inkSoft)
            FlowRow(spacing: 8) {
                ForEach(reply.refinements) { refinement in
                    Button {
                        refine(refinement)
                    } label: {
                        Label(refinement.title, systemImage: refinement.symbolName)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Palette.ink)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 9)
                            .background(Palette.surface, in: .capsule)
                            .overlay { Capsule().stroke(Palette.hairline, lineWidth: 1) }
                    }
                    .buttonStyle(ExperienceCardPressStyle())
                }
            }
        }
        .padding(.top, 2)
    }

    /// Says plainly where the results came from, so local demo matching is never mistaken
    /// for a live marketplace.
    private func sourceNotice(_ text: String) -> some View {
        Label(text, systemImage: "info.circle")
            .font(.caption2)
            .foregroundStyle(Palette.inkSoft)
            .padding(.top, 4)
    }

    // MARK: - Actions

    private func send(_ text: String) {
        let context = AssistantContextBuilder.make(store: store, location: location)
        Task { await conversation.send(text, context: context) }
    }

    private func refine(_ refinement: AssistantRefinement) {
        let context = AssistantContextBuilder.make(store: store, location: location)
        Task { await conversation.refine(refinement, context: context) }
    }

    private func open(_ provider: Provider) {
        openedProvider = provider
    }

    private func book(_ offer: AssistantOffer, at slot: Date) {
        bookingFlow = BookingFlow(
            provider: offer.provider,
            service: offer.service,
            preselectedSlot: slot
        )
    }
}

/// Wraps chips onto as many lines as they need.
///
/// Follow-up actions vary in width and count, and a horizontal scroll would hide some of
/// them — a refinement the client cannot see is a refinement that does not exist.
struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
