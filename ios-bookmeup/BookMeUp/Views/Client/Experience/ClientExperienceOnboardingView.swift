import SwiftUI

/// The Client Experience questionnaire, one question per screen.
///
/// This is not an administrative form: the client is being asked how they would like
/// their visit to feel. The flow keeps every answer in memory while it runs, so going
/// back always shows what was already chosen, and writes once at the end — onboarding is
/// marked complete only when that save happens.
///
/// The questions come from `ClientExperienceCatalog`. This view knows how many there are
/// and nothing about what they ask.
struct ClientExperienceOnboardingView: View {
    @Environment(BookMeUpStore.self) private var store
    @Environment(BusinessStore.self) private var business
    @Environment(\.dismiss) private var dismiss

    @State private var index = 0
    @State private var answers: [String: ExperienceAnswer] = [:]
    @State private var isLoaded = false
    @State private var saved = false

    private var questions: [ExperienceQuestion] {
        ClientExperienceCatalog.questions(for: business.business)
    }

    private var current: ExperienceQuestion? {
        questions.indices.contains(index) ? questions[index] : nil
    }

    private var isLastStep: Bool { index == questions.count - 1 }

    /// A required question blocks the flow until it is answered; an optional one never
    /// does — it offers to be skipped instead.
    private var canContinue: Bool {
        guard let current else { return false }
        guard current.isRequired else { return true }
        return !(answers[current.id]?.isEmpty ?? true)
    }

    private var isCurrentAnswered: Bool {
        guard let current else { return false }
        return !(answers[current.id]?.isEmpty ?? true)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            questionArea
            footer
        }
        .background(Palette.bone)
        .task { load() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            if index == 0 {
                Text("Padėkite mums sukurti vizitą, pritaikytą būtent Jums.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
            ExperienceProgressView(step: index + 1, total: questions.count)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 18)
    }

    // MARK: - Question

    private var questionArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let current {
                    ExperienceQuestionView(
                        question: current,
                        answer: binding(for: current)
                    )
                    .id(current.id)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .animation(.spring(response: 0.38, dampingFraction: 0.88), value: index)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 10) {
            Button {
                advance()
            } label: {
                Text(isLastStep ? "Išsaugoti" : "Tęsti")
            }
            .buttonStyle(MarigoldButtonStyle(isDisabled: !canContinue))
            .disabled(!canContinue)
            .sensoryFeedback(.success, trigger: saved)

            HStack(spacing: 10) {
                if index > 0 {
                    Button {
                        withAnimation { index -= 1 }
                    } label: {
                        Label("Atgal", systemImage: "chevron.left")
                    }
                    .buttonStyle(QuietButtonStyle())
                }

                if let current, !current.isRequired, !isCurrentAnswered {
                    Button {
                        advance()
                    } label: {
                        Text("Praleisti")
                    }
                    .buttonStyle(QuietButtonStyle(tint: Palette.inkSoft))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Palette.bone)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Palette.hairline)
                .frame(height: 1)
        }
    }

    // MARK: - Flow

    private func binding(for question: ExperienceQuestion) -> Binding<ExperienceAnswer?> {
        Binding(
            get: { answers[question.id] },
            set: { answers[question.id] = $0 }
        )
    }

    /// Restores anything already answered, so a client who reopens an unfinished
    /// questionnaire — or who edited their profile before — never starts from blank.
    private func load() {
        guard !isLoaded else { return }
        isLoaded = true
        if let profile = store.signedInExperienceProfile {
            answers = profile.answers
        }
    }

    private func advance() {
        if isLastStep {
            save()
        } else {
            withAnimation { index += 1 }
        }
    }

    private func save() {
        guard let client = store.signedInClient else { return }
        store.saveExperienceAnswers(
            answers,
            for: client.id,
            businessID: business.business.id,
            completingOnboarding: true
        )
        saved = true
        dismiss()
    }
}
