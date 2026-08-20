import SwiftUI

/// „Mano vizito pasirinkimai“ — the client editing what they answered.
///
/// Preferences change, so this must never make someone repeat a seven-screen flow to
/// swap one answer. Everything is on one page, built from the same catalogue and the
/// same components as onboarding, and saving writes to the same profile the specialist
/// reads — there is no second copy anywhere.
struct ClientExperienceEditorView: View {
    @Environment(BookMeUpStore.self) private var store
    @Environment(BusinessStore.self) private var business
    @Environment(\.dismiss) private var dismiss

    @State private var answers: [String: ExperienceAnswer] = [:]
    @State private var isLoaded = false
    @State private var savedAt: Date?

    private var questions: [ExperienceQuestion] {
        ClientExperienceCatalog.questions(for: business.business)
    }

    private var profile: ClientExperienceProfile? { store.signedInExperienceProfile }

    private var hasChanges: Bool {
        answers.filter { !$0.value.isEmpty } != (profile?.answers ?? [:]).filter { !$0.value.isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                intro

                ForEach(questions) { question in
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(question.title)
                                .font(.headline)
                                .foregroundStyle(Palette.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            if let subtitle = question.subtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(Palette.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        ExperienceQuestionView(
                            question: question,
                            answer: binding(for: question),
                            showsTitle: false
                        )
                    }
                }

                Button {
                    save()
                } label: {
                    Text("Išsaugoti")
                }
                .buttonStyle(MarigoldButtonStyle(isDisabled: !hasChanges))
                .disabled(!hasChanges)
                .sensoryFeedback(.success, trigger: savedAt)

                privacyNote
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Mano vizito pasirinkimai")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.bone, for: .navigationBar)
        .task { load() }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Šiuos pasirinkimus prieš vizitą mato Jus aptarnaujantis meistras.")
                .font(.subheadline)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let updated = profile?.updatedAt {
                Text("Atnaujinta \(updated.dayText)")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 16)
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.forest)
                .frame(width: 32, height: 32)
                .background(Palette.eucalyptus.opacity(0.4), in: .rect(cornerRadius: 10))
            Text("Pasirinkimus galite bet kada pakeisti arba ištrinti. Jie skirti tik vizitui — naujienų ir pasiūlymų sutikimas nustatomas atskirai profilyje.")
                .font(.caption)
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .cardSurface(padding: 14, cornerRadius: 18)
    }

    private func binding(for question: ExperienceQuestion) -> Binding<ExperienceAnswer?> {
        Binding(
            get: { answers[question.id] },
            set: { answers[question.id] = $0 }
        )
    }

    private func load() {
        guard !isLoaded else { return }
        isLoaded = true
        answers = profile?.answers ?? [:]
    }

    /// Saves without touching the onboarding flag: a client editing preferences has
    /// already finished onboarding and must never be sent through it again.
    private func save() {
        guard let client = store.signedInClient else { return }
        store.saveExperienceAnswers(
            answers,
            for: client.id,
            businessID: business.business.id,
            completingOnboarding: false
        )
        savedAt = Date()
        dismiss()
    }
}
