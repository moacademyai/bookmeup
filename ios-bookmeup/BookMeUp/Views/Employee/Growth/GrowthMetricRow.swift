import SwiftUI

/// One historical number and how it moved.
///
/// The arrow direction and the colour are decided separately: cancellations falling is
/// green with a down arrow, cancellations rising is red with an up arrow. Colouring
/// every rise green would quietly congratulate the specialist for a worse month.
struct GrowthMetricRow: View {
    let metric: GrowthMetric

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(metric.title)
                .font(.subheadline)
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            Text(metric.value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(Palette.ink)
                .lineLimit(1)

            if let change = metric.changeText {
                Text(change)
                    .font(.caption.weight(.medium).monospacedDigit())
                    .foregroundStyle(changeColor)
                    .frame(minWidth: 48, alignment: .trailing)
            } else {
                // Keeps every value column aligned when one metric has no history.
                Color.clear.frame(width: 48, height: 1)
            }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    private var changeColor: Color {
        guard let improved = metric.isImprovement else { return Palette.inkSoft }
        return improved ? Palette.forest : Palette.terracotta
    }
}
