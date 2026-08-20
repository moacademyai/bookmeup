import SwiftUI

/// The photo gallery at the top of a business profile.
///
/// Photography is how a client decides whether a place feels like theirs, so it gets the
/// full width and a natural horizontal swipe. The page dots are the only chrome — a
/// gallery that needs arrows and counters is a gallery that got in its own way.
struct BusinessGallery: View {
    let photoNames: [String]
    var height: CGFloat = 260

    @State private var index = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $index) {
                ForEach(Array(photoNames.enumerated()), id: \.offset) { offset, name in
                    AssetImage(name: name, height: height, cornerRadius: 0)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: height)

            if photoNames.count > 1 {
                pageDots
                    .padding(.bottom, 14)
            }
        }
        .frame(height: height)
        .accessibilityLabel("Verslo nuotraukos")
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<photoNames.count, id: \.self) { dot in
                Capsule()
                    .fill(Color(hex: 0xF6F3E8).opacity(dot == index ? 1 : 0.45))
                    .frame(width: dot == index ? 18 : 6, height: 6)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color(hex: 0x10201D).opacity(0.35), in: .capsule)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: index)
    }
}
