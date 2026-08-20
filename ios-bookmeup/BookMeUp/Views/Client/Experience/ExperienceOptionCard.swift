import SwiftUI

/// One answer, as a card the client taps anywhere on.
///
/// No radio buttons: the whole surface is the target, the selected state is a filled
/// eucalyptus card with a forest border, and the indicator only confirms what the colour
/// already said. Multi-select uses a square mark, single-select a round one, so the
/// client can tell how many answers are allowed before tapping.
struct ExperienceOptionCard: View {
    let option: ExperienceOption
    let isSelected: Bool
    let allowsMultiple: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let symbol = option.symbolName {
                    Image(systemName: symbol)
                        .font(.headline)
                        .foregroundStyle(isSelected ? Palette.forest : Palette.inkSoft)
                        .frame(width: 42, height: 42)
                        .background(
                            (isSelected ? Palette.eucalyptus.opacity(0.75) : Palette.ink.opacity(0.05)),
                            in: .circle
                        )
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(option.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if let detail = option.detail {
                        Text(detail)
                            .font(.footnote)
                            .foregroundStyle(Palette.inkSoft)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 8)

                indicator
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
            .background(
                isSelected ? Palette.eucalyptus.opacity(0.34) : Palette.surface,
                in: .rect(cornerRadius: 20)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Palette.forest : Palette.hairline,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .contentShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(ExperienceCardPressStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var indicator: some View {
        ZStack {
            if allowsMultiple {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Palette.forest : Palette.ink.opacity(0.18), lineWidth: 2)
                    .frame(width: 26, height: 26)
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Palette.forest)
                        .frame(width: 26, height: 26)
                }
            } else {
                Circle()
                    .stroke(isSelected ? Palette.forest : Palette.ink.opacity(0.18), lineWidth: 2)
                    .frame(width: 26, height: 26)
                if isSelected {
                    Circle()
                        .fill(Palette.forest)
                        .frame(width: 26, height: 26)
                }
            }

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Palette.bone)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

/// Soft press feedback shared by every tappable questionnaire card.
struct ExperienceCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.26, dampingFraction: 0.75), value: configuration.isPressed)
    }
}
