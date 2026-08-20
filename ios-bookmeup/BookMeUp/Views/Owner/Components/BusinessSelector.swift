import SwiftUI

/// The business and location the owner is currently looking at.
///
/// It is a selector from day one — a second address changes what it lists, not how
/// any screen behind it is built.
struct BusinessSelector: View {
    let businessName: String
    let locationName: String
    let roleName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(businessName)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Palette.bone)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            HStack(spacing: 6) {
                Text(locationName)
                    .font(.subheadline)
                    .foregroundStyle(Palette.eucalyptus.opacity(0.85))
                Text("·")
                    .foregroundStyle(Palette.eucalyptus.opacity(0.5))
                Text(roleName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.eucalyptus)
            }
        }
    }
}

/// Switches the active location. Hidden when a business has a single address, so a
/// one-location salon never carries multi-location chrome.
struct LocationSelector: View {
    let locations: [BusinessLocation]
    let selectedID: UUID
    let onSelect: (UUID) -> Void

    private var selected: BusinessLocation? {
        locations.first { $0.id == selectedID }
    }

    var body: some View {
        if locations.count > 1 {
            Menu {
                ForEach(locations) { location in
                    Button {
                        onSelect(location.id)
                    } label: {
                        Label(location.name, systemImage: location.id == selectedID ? "checkmark" : "mappin")
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                    Text(selected?.city ?? "Lokacija")
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.bone)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Palette.pineElevated, in: .capsule)
                .overlay { Capsule().stroke(Palette.eucalyptus.opacity(0.35), lineWidth: 1) }
            }
            .accessibilityLabel("Pasirinkti lokaciją")
        }
    }
}
