import SwiftUI

/// Revenue per month as plain bars.
///
/// Hand-drawn rather than a charting library on purpose: this needs one colour, no
/// gridlines, no legend and no axis furniture. The most recent month is the only one
/// drawn in full strength, because that is the one the specialist is living in.
struct RevenueTrendChart: View {
    let points: [MonthlyRevenuePoint]

    @State private var isRevealed = false

    private var maximum: Double {
        max(points.map(\.revenue).max() ?? 0, 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                bar(point, isLatest: index == points.count - 1)
            }
        }
        .frame(height: 132)
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) { isRevealed = true }
        }
    }

    private func bar(_ point: MonthlyRevenuePoint, isLatest: Bool) -> some View {
        VStack(spacing: 6) {
            Text(point.revenue > 0 ? compact(point.revenue) : "—")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(isLatest ? Palette.ink : Palette.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            GeometryReader { proxy in
                VStack {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isLatest ? Palette.forest : Palette.forest.opacity(0.28))
                        .frame(
                            height: isRevealed
                                ? max(proxy.size.height * (point.revenue / maximum), point.revenue > 0 ? 4 : 2)
                                : 2
                        )
                }
            }

            Text(point.shortLabel)
                .font(.caption2)
                .foregroundStyle(Palette.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(point.month.monthText), \(point.revenue.asEuro)")
    }

    /// "2,8 tūkst. €" keeps four bars readable side by side on a phone.
    private func compact(_ value: Double) -> String {
        guard value >= 1000 else { return value.asEuro }
        return "\(NumberText.oneDecimal(value / 1000)) tūkst."
    }
}
