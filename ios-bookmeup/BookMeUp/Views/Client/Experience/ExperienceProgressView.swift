import SwiftUI

/// The "1 iš 7" header of the questionnaire.
///
/// A counter alone reads like a form; the bar underneath is what makes the flow feel
/// short. Both are driven by the catalogue, so adding a question changes the total
/// without anything here being touched.
struct ExperienceProgressView: View {
    let step: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(step) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(step) iš \(total)")
                    .font(.footnote.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Palette.forest)
                    .contentTransition(.numericText())
                Spacer(minLength: 8)
                Text("Vizito pasirinkimai")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Palette.ink.opacity(0.08))
                    Capsule()
                        .fill(Palette.forest)
                        .frame(width: max(geometry.size.width * progress, 6))
                }
            }
            .frame(height: 6)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: step)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Klausimas \(step) iš \(total)")
    }
}
