import SwiftUI

/// A quiet weekly target.
///
/// One line of type and one thin bar. Professional motivation means showing the
/// specialist where they stand against their own normal week — not badges, streaks
/// or celebration. The bar fills with a short animation the first time it appears.
struct EmployeeWeeklyGoalRow: View {
    let goal: EmployeeWeeklyGoal

    @State private var isRevealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Savaitės tikslas")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Palette.ink)
                Spacer(minLength: 8)
                Text("\(goal.earned.asEuro) / \(goal.target.asEuro)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Palette.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Palette.hairline)
                    Capsule()
                        .fill(goal.isReached ? Palette.forest : Palette.marigold)
                        .frame(width: proxy.size.width * (isRevealed ? goal.progress : 0))
                }
            }
            .frame(height: 5)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Palette.inkSoft)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) { isRevealed = true }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Savaitės tikslas, \(goal.percentText)")
    }

    private var subtitle: String {
        if goal.isReached { return "Savaitės tikslas pasiektas" }
        return "\(goal.percentText) · liko \(goal.remaining.asEuro)"
    }
}
