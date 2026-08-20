import SwiftUI

/// Renders one Beauty Passport photo from its reference, whatever the source is:
/// bundled demo photography, a photo the specialist took, or a future cloud URL.
struct PassportPhotoView: View {
    let reference: PassportPhotoReference?
    var height: CGFloat
    var width: CGFloat?
    var cornerRadius: CGFloat = 18
    var placeholderSymbol: String = "camera"
    var placeholderText: String?

    @State private var image: UIImage?

    var body: some View {
        Palette.eucalyptus.opacity(0.28)
            .frame(width: width, height: height)
            .overlay { content }
            .clipShape(.rect(cornerRadius: cornerRadius))
            .task(id: reference) {
                image = reference.flatMap { PassportPhotoStore.image(for: $0) }
            }
    }

    @ViewBuilder
    private var content: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .allowsHitTesting(false)
        } else if case .remote(let url) = reference {
            AsyncImage(url: url) { phase in
                if let remote = phase.image {
                    remote.resizable().aspectRatio(contentMode: .fill)
                } else {
                    ProgressView().tint(Palette.forest)
                }
            }
            .allowsHitTesting(false)
        } else {
            VStack(spacing: 6) {
                Image(systemName: placeholderSymbol)
                    .font(.headline)
                if let placeholderText {
                    Text(placeholderText)
                        .font(.caption)
                }
            }
            .foregroundStyle(Palette.inkSoft)
            .allowsHitTesting(false)
        }
    }
}
