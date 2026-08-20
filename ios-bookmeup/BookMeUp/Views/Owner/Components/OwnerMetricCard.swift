import SwiftUI

/// One number of the business, on the dark command-centre surface.
///
/// A metric card never invents a value: when there is nothing to count it shows the
/// zero and its caption explains what would fill it.
struct OwnerMetricCard: View {
    let value: String
    let caption: String
    let symbolName: String
    var tint: Color = Palette.eucalyptus
    var detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbolName)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.16), in: .circle)

            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(Palette.bone)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(caption)
                .font(.caption2)
                .foregroundStyle(Palette.eucalyptus.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)

            if let detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(Palette.eucalyptus.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Palette.pineElevated, in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Palette.eucalyptus.opacity(0.16), lineWidth: 1)
        }
    }
}
