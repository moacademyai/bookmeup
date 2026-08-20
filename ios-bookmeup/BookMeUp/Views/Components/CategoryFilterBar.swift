import SwiftUI

/// What a discovery surface is currently filtered to.
///
/// `.forYou` is not a category — it is the absence of a filter plus this client's own
/// ordering. That distinction is what keeps personalisation from ever becoming a cage:
/// the client can always step out of "Tau" into any industry on the platform.
nonisolated enum DiscoveryFilter: Hashable {
    case forYou
    case category(ServiceCategory)

    var title: String {
        switch self {
        case .forYou: "Tau"
        case .category(let category): category.title
        }
    }

    var symbolName: String {
        switch self {
        case .forYou: "sparkles"
        case .category(let category): category.symbolName
        }
    }

    var category: ServiceCategory? {
        guard case .category(let category) = self else { return nil }
        return category
    }
}

/// Horizontally scrolling category chips: Tau · the client's industries · Daugiau.
///
/// Only the first few categories are inline; the rest live behind "Daugiau" so the bar
/// stays readable as the platform adds industries. Nothing is hidden from the client —
/// it is one tap away, not removed.
struct CategoryFilterBar: View {
    let categories: [ServiceCategory]
    @Binding var selection: DiscoveryFilter
    /// How many categories to show before the overflow button.
    var inlineLimit: Int = 4

    @State private var showsAll = false

    private var inlineCategories: [ServiceCategory] {
        Array(categories.prefix(inlineLimit))
    }

    private var overflowCategories: [ServiceCategory] {
        Array(categories.dropFirst(inlineLimit))
    }

    /// A category picked from "Daugiau" takes an inline slot, so the client never has to
    /// dig for the thing they just chose.
    private var visibleCategories: [ServiceCategory] {
        guard let selected = selection.category, !inlineCategories.contains(selected) else {
            return inlineCategories
        }
        return [selected] + inlineCategories.dropLast()
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(.forYou)
                ForEach(visibleCategories) { category in
                    chip(.category(category))
                }
                if !overflowCategories.isEmpty {
                    moreChip
                }
            }
            .padding(.vertical, 2)
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .sheet(isPresented: $showsAll) {
            allCategoriesSheet
        }
    }

    private func chip(_ filter: DiscoveryFilter) -> some View {
        let isSelected = selection == filter
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                selection = isSelected && filter != .forYou ? .forYou : filter
            }
        } label: {
            Label(filter.title, systemImage: filter.symbolName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? Palette.onPine : Palette.ink)
                .lineLimit(1)
                // The chip takes the width its words need; the row scrolls instead of
                // shrinking a long industry name to fit.
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? Palette.pine : Palette.surface, in: .capsule)
                .overlay {
                    Capsule().stroke(isSelected ? Color.clear : Palette.hairline, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    private var moreChip: some View {
        Button {
            showsAll = true
        } label: {
            Label("Daugiau", systemImage: "ellipsis")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Palette.surface, in: .capsule)
                .overlay { Capsule().stroke(Palette.hairline, lineWidth: 1) }
        }
        .buttonStyle(.plain)
    }

    private var allCategoriesSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(categories) { category in
                        Button {
                            selection = .category(category)
                            showsAll = false
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: category.symbolName)
                                    .font(.headline)
                                    .foregroundStyle(Palette.forest)
                                    .frame(width: 44, height: 44)
                                    .background(Palette.eucalyptus.opacity(0.4), in: .circle)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(category.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Palette.ink)
                                    Text(category.summary)
                                        .font(.caption)
                                        .foregroundStyle(Palette.inkSoft)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer(minLength: 4)
                                if selection.category == category {
                                    Image(systemName: "checkmark")
                                        .font(.footnote.weight(.bold))
                                        .foregroundStyle(Palette.forest)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cardSurface(padding: 14, cornerRadius: 18)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Palette.bone)
            .scrollIndicators(.hidden)
            .navigationTitle("Visos sritys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Uždaryti") { showsAll = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationContentInteraction(.scrolls)
    }
}
