import SwiftUI

/// Country code picker for the phone field: flag, name and calling code, searchable.
struct PhoneCountryPickerSheet: View {
    @Binding var selection: PhoneCountry

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var results: [PhoneCountry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return PhoneFormat.countries }
        return PhoneFormat.countries.filter { country in
            country.name.localizedCaseInsensitiveContains(trimmed)
                || country.dialText.contains(trimmed)
                || country.region.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            List(results) { country in
                Button {
                    selection = country
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text(country.flag)
                            .font(.title3)
                        Text(country.name)
                            .font(.subheadline)
                            .foregroundStyle(Palette.ink)
                        Spacer(minLength: 8)
                        Text(country.dialText)
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Palette.inkSoft)
                        if country.id == selection.id {
                            Image(systemName: "checkmark")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Palette.forest)
                        }
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: "Ieškoti šalies")
            .navigationTitle("Šalies kodas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Uždaryti") { dismiss() }
                }
            }
        }
    }
}
