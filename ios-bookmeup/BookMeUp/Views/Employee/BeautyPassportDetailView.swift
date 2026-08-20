import SwiftUI

/// The full Beauty Passport record of one visit, with the client's earlier records
/// underneath. Selecting an older record shows exactly that visit's photos and recipe.
struct BeautyPassportDetailView: View {
    let client: Client
    let entry: BeautyPassportEntry

    @Environment(BookMeUpStore.self) private var store
    @State private var selectedEntryID: UUID?

    private var entries: [BeautyPassportEntry] { store.passportEntries(for: client) }

    /// The record currently on screen — the one opened, or the one picked from history.
    private var selected: BeautyPassportEntry {
        entries.first { $0.id == (selectedEntryID ?? entry.id) } ?? entry
    }

    private var earlier: [BeautyPassportEntry] {
        entries.filter { $0.id != selected.id }
    }

    private var visitNumberText: String? {
        guard let booking = store.booking(for: selected), booking.visitNumber > 0 else { return nil }
        return "Vizitas Nr. \(booking.visitNumber)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Color.clear.frame(height: 0).id(topAnchor)

                photosSection
                visitSection
                recipeSection
                if !selected.products.isEmpty {
                    productsSection
                }
                if let note = selected.note {
                    noteSection(note)
                }
                if !earlier.isEmpty {
                    historySection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle("Grožio pasas")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(Palette.bone, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: selected.id)
    }

    private let topAnchor = "passport.top"

    // MARK: - Photos

    private var photosSection: some View {
        HStack(spacing: 12) {
            photoColumn(title: "Prieš", reference: selected.beforePhoto)
            photoColumn(title: "Po", reference: selected.afterPhoto)
        }
        .transition(.opacity)
        .id(selected.id)
    }

    private func photoColumn(title: String, reference: PassportPhotoReference?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            PassportPhotoView(
                reference: reference,
                height: 220,
                cornerRadius: 18,
                placeholderText: "Nėra"
            )
            .frame(maxWidth: .infinity)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.inkSoft)
                .textCase(.uppercase)
                .kerning(0.6)
        }
    }

    // MARK: - Visit

    private var visitSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(selected.date.dayText)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Spacer(minLength: 4)
                if let visitNumberText {
                    Text(visitNumberText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.forest)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Palette.eucalyptus.opacity(0.35), in: .capsule)
                }
            }

            Label(selected.serviceName, systemImage: selected.category.symbolName)
                .font(.subheadline)
                .foregroundStyle(Palette.inkSoft)
            Label(selected.specialistName, systemImage: "person")
                .font(.subheadline)
                .foregroundStyle(Palette.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 16)
    }

    // MARK: - Recipe

    private var recipeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Receptas")

            VStack(alignment: .leading, spacing: 14) {
                if selected.hasSummary {
                    Text(selected.summary)
                        .font(.subheadline)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if selected.filledDetails.isEmpty && !selected.hasSummary {
                    Text("Šio vizito receptas neužpildytas.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.inkSoft)
                } else {
                    ForEach(selected.filledDetails) { detail in
                        recipeRow(detail)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(padding: 16)
        }
    }

    private func recipeRow(_ detail: BeautyPassportDetail) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: detail.symbolName)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.forest)
                .frame(width: 30, height: 30)
                .background(Palette.eucalyptus.opacity(0.35), in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(detail.title)
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
                Text(detail.value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Products

    private var productsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Naudoti produktai")

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 130), spacing: 8)],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(selected.products, id: \.self) { product in
                    Label(product, systemImage: "drop.halffull")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Palette.surface, in: .capsule)
                        .overlay { Capsule().stroke(Palette.hairline, lineWidth: 1) }
                }
            }
        }
    }

    // MARK: - Note

    private func noteSection(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Darbuotojo pastaba")

            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(Palette.marigold)
                    .frame(width: 3)
                    .clipShape(.capsule)
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(padding: 16)
        }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Ankstesni įrašai", accessory: "\(entries.count)")

            VStack(spacing: 0) {
                ForEach(Array(earlier.enumerated()), id: \.element.id) { index, item in
                    Button {
                        selectedEntryID = item.id
                    } label: {
                        historyRow(item)
                    }
                    .buttonStyle(.plain)

                    if index < earlier.count - 1 {
                        Divider().overlay(Palette.hairline)
                    }
                }
            }
            .cardSurface(padding: 12)
        }
    }

    private func historyRow(_ item: BeautyPassportEntry) -> some View {
        HStack(spacing: 12) {
            PassportPhotoView(
                reference: item.afterPhoto,
                height: 56,
                width: 56,
                cornerRadius: 14
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(item.date.dayText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Text(item.serviceName)
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.inkSoft.opacity(0.6))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(.rect)
    }
}
