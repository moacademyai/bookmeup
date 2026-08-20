import SwiftUI

/// The one create-client form in the product.
///
/// It is opened from the client base and from a booking in progress; both use the same
/// fields, the same phone normalisation and the same duplicate check. Only what happens
/// after a successful save differs, and that is left to `onCreated`.
struct NewClientSheet: View {
    /// What the search already knew, so nothing is typed twice.
    var prefill: NewClientPrefill
    /// Label of the action offered when the number already belongs to someone.
    var duplicateActionTitle: String
    /// The created — or already existing — client the caller should continue with.
    var onCreated: (Client) -> Void

    /// The text fields of the form, so a tap anywhere on a card can point at one.
    private enum Field: Hashable {
        case firstName
        case lastName
        case email
        case note
    }

    @Environment(BookMeUpStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @FocusState private var focusedField: Field?

    @State private var firstName: String
    @State private var lastName: String
    @State private var phone: String
    @State private var country: PhoneCountry
    @State private var email = ""
    @State private var note = ""
    /// The client already holding this number, when the save was blocked.
    @State private var duplicate: Client?
    /// Set only after a save attempt, so the form does not scold while typing.
    @State private var showsPhoneError = false

    init(
        prefill: NewClientPrefill = NewClientPrefill(),
        duplicateActionTitle: String = "Atidaryti klientą",
        onCreated: @escaping (Client) -> Void
    ) {
        self.prefill = prefill
        self.duplicateActionTitle = duplicateActionTitle
        self.onCreated = onCreated
        _firstName = State(initialValue: prefill.firstName)
        _lastName = State(initialValue: prefill.lastName)
        _phone = State(initialValue: prefill.phone)
        _country = State(
            initialValue: PhoneFormat.detectedCountry(prefill.phone) ?? PhoneFormat.defaultCountry
        )
    }

    private var trimmedFirstName: String {
        firstName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedPhone: String {
        phone.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The number exactly as it will be stored.
    private var normalizedPhone: String? {
        PhoneFormat.e164(phone, region: country.region)
    }

    private var canSave: Bool {
        !trimmedFirstName.isEmpty && normalizedPhone != nil
    }

    private var phoneError: String? {
        guard showsPhoneError, normalizedPhone == nil else { return nil }
        return trimmedPhone.isEmpty
            ? "Įvesk telefono numerį"
            : "Toks numeris neegzistuoja \(country.name) formatu"
    }

    private var phoneHint: String? {
        normalizedPhone.map { "Bus išsaugota kaip \($0)" }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    nameSection
                    contactSection
                    noteSection
                    if let duplicate {
                        duplicateCard(duplicate)
                    }
                    saveButton
                }
                .padding(20)
            }
            .background(Palette.bone)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Naujas klientas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Uždaryti") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationContentInteraction(.scrolls)
    }

    // MARK: - Sections

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Vardas")
            VStack(spacing: 10) {
                field(title: "Vardas *", text: $firstName, field: .firstName, capitalization: .words)
                field(title: "Pavardė", text: $lastName, field: .lastName, capitalization: .words)
            }
        }
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Kontaktai")
            VStack(spacing: 10) {
                PhoneNumberField(
                    country: $country,
                    number: $phone,
                    errorText: phoneError,
                    hintText: phoneHint
                )
                .onChange(of: phone) { _, _ in
                    duplicate = nil
                    showsPhoneError = false
                }

                field(
                    title: "El. paštas",
                    text: $email,
                    field: .email,
                    capitalization: .never,
                    keyboard: .emailAddress
                )
            }
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Vidinė pastaba")
            TextField("Matoma tik tau", text: $note, axis: .vertical)
                .lineLimit(2...5)
                .font(.subheadline)
                .foregroundStyle(Palette.ink)
                .focused($focusedField, equals: .note)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(14)
                .background(Palette.surface, in: .rect(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            focusedField == .note ? Palette.forest : Palette.hairline,
                            lineWidth: focusedField == .note ? 1.5 : 1
                        )
                }
                // The whole note card is the target, not just the two text lines.
                .contentShape(Rectangle())
                .onTapGesture { focusedField = .note }
        }
    }

    /// One input card. The card itself carries the tap target, while the field inside
    /// keeps its own gestures for the caret and text selection.
    private func field(
        title: String,
        text: Binding<String>,
        field: Field,
        capitalization: TextInputAutocapitalization,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        let isFocused = focusedField == field
        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Palette.inkSoft)
            TextField("", text: text)
                .font(.subheadline)
                .foregroundStyle(Palette.ink)
                .textInputAutocapitalization(capitalization)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .focused($focusedField, equals: field)
                .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: .rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isFocused ? Palette.forest : Palette.hairline,
                    lineWidth: isFocused ? 1.5 : 1
                )
        }
        .contentShape(Rectangle())
        .onTapGesture { focusedField = field }
    }

    // MARK: - Duplicate

    private func duplicateCard(_ client: Client) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.terracotta)
                    .frame(width: 30, height: 30)
                    .background(Palette.terracotta.opacity(0.18), in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Klientas su šiuo telefono numeriu jau yra.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(client.fullName) · \(client.phoneDisplay)")
                        .font(.caption)
                        .foregroundStyle(Palette.inkSoft)
                }
                Spacer(minLength: 0)
            }

            Button {
                finish(with: client)
            } label: {
                Label(duplicateActionTitle, systemImage: "arrow.up.right")
            }
            .buttonStyle(QuietButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 16)
    }

    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text("Išsaugoti klientą")
        }
        .buttonStyle(MarigoldButtonStyle(isDisabled: !canSave))
        .disabled(!canSave)
    }

    // MARK: - Actions

    private func save() {
        let outcome = store.createClient(
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            email: email,
            note: note,
            region: country.region
        )
        switch outcome {
        case .created(let client):
            finish(with: client)
        case .duplicate(let existing):
            duplicate = existing
        case .invalidPhone:
            showsPhoneError = true
        }
    }

    private func finish(with client: Client) {
        onCreated(client)
        dismiss()
    }
}
