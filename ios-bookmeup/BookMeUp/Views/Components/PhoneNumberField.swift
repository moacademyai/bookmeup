import SwiftUI

/// Phone input with a country picker in front of it.
///
/// The field keeps the typed text exactly as entered; turning it into E.164 is the
/// job of `PhoneFormat` at save time. A pasted international number moves the flag
/// to its country automatically.
struct PhoneNumberField: View {
    @Binding var country: PhoneCountry
    @Binding var number: String
    var title: String = "Telefono numeris *"
    /// Shown in red under the field when the number cannot be saved.
    var errorText: String?
    /// Shown in grey under the field, e.g. the form the number will be stored in.
    var hintText: String?

    @State private var showsCountryPicker = false
    @FocusState private var isNumberFocused: Bool

    private var hasError: Bool { errorText != nil }

    private var borderColor: Color {
        if hasError { return Palette.terracotta }
        return isNumberFocused ? Palette.forest : Palette.hairline
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)

                HStack(spacing: 10) {
                    Button {
                        showsCountryPicker = true
                    } label: {
                        HStack(spacing: 5) {
                            Text(country.flag)
                                .font(.title3)
                            Text(country.dialText)
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(Palette.ink)
                            Image(systemName: "chevron.down")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Palette.inkSoft)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Šalies kodas \(country.name)")

                    Rectangle()
                        .fill(Palette.hairline)
                        .frame(width: 1, height: 22)

                    TextField("612 34 567", text: $number)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Palette.ink)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .autocorrectionDisabled()
                        .focused($isNumberFocused)
                        .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
                        .contentShape(Rectangle())
                        .onChange(of: number) { _, value in
                            guard let detected = PhoneFormat.detectedCountry(value) else { return }
                            country = detected
                        }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: isNumberFocused || hasError ? 1.5 : 1)
            }
            // Anywhere on the card opens the number pad; the country button sits on top
            // of this and keeps its own tap.
            .contentShape(Rectangle())
            .onTapGesture { isNumberFocused = true }

            if let errorText {
                Text(errorText)
                    .font(.caption)
                    .foregroundStyle(Palette.terracotta)
                    .padding(.horizontal, 4)
            } else if let hintText {
                Text(hintText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Palette.inkSoft)
                    .padding(.horizontal, 4)
            }
        }
        .sheet(isPresented: $showsCountryPicker) {
            PhoneCountryPickerSheet(selection: $country)
        }
    }
}
