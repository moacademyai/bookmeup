import SwiftUI

/// Renders any Client Experience question.
///
/// One view handles all three kinds, which is what keeps the seven V1 questions from
/// becoming seven near-identical screens. Both the onboarding flow and the profile
/// editor use it, so an answer looks and behaves the same in either place.
struct ExperienceQuestionView: View {
    let question: ExperienceQuestion
    @Binding var answer: ExperienceAnswer?
    /// Onboarding shows the question as a large title; the editor shows it as a section.
    var showsTitle: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if showsTitle {
                VStack(alignment: .leading, spacing: 8) {
                    Text(question.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle = question.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Palette.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            switch question.kind {
            case .singleSelect, .multiSelect:
                VStack(spacing: 10) {
                    ForEach(question.options) { option in
                        ExperienceOptionCard(
                            option: option,
                            isSelected: answer?.contains(option.id) ?? false,
                            allowsMultiple: question.allowsMultiple
                        ) {
                            select(option)
                        }
                    }
                }
            case .text:
                ExperienceTextInput(
                    placeholder: question.placeholder ?? "",
                    text: textBinding
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var textBinding: Binding<String> {
        Binding(
            get: { if case .text(let value) = answer { value } else { "" } },
            set: { answer = .text($0) }
        )
    }

    private func select(_ option: ExperienceOption) {
        let current = answer ?? .selection([])
        answer = current.toggling(option.id, allowsMultiple: question.allowsMultiple)
    }
}
