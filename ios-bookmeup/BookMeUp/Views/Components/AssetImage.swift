import SwiftUI

/// Bundled photography with a graceful fallback, cropped like a small magazine cover.
struct AssetImage: View {
    let name: String
    var height: CGFloat
    var width: CGFloat?
    var cornerRadius: CGFloat = 18

    var body: some View {
        Palette.eucalyptus.opacity(0.45)
            .frame(width: width, height: height)
            .overlay {
                if let image = UIImage(named: name) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                } else {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(Palette.forest.opacity(0.5))
                        .allowsHitTesting(false)
                }
            }
            .clipShape(.rect(cornerRadius: cornerRadius))
    }
}

/// Round initials avatar used for people (clients and specialists).
struct InitialsAvatar: View {
    let name: String
    var size: CGFloat = 44
    var tint: Color = Palette.eucalyptus

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first }.map(String.init).joined().uppercased()
    }

    var body: some View {
        Circle()
            .fill(tint.opacity(0.55))
            .frame(width: size, height: size)
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundStyle(Palette.forest)
            }
    }
}
