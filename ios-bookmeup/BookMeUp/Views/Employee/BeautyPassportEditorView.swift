import PhotosUI
import SwiftUI

/// Which of the two passport photos is being worked on.
private enum PassportPhotoSlot: String, Identifiable, Hashable {
    case before
    case after

    var id: String { rawValue }

    var title: String {
        switch self {
        case .before: "Prieš"
        case .after: "Po"
        }
    }
}

/// The specialist's working surface for one visit's Beauty Passport.
///
/// Everything here belongs to a single record that already exists in the store, so
/// every edit is written straight back — there is no Save button to forget and no
/// state that lives only on this screen.
struct BeautyPassportEditorView: View {
    let entryID: UUID

    @Environment(BookMeUpStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var noteText = ""
    @State private var didLoadNote = false
    @State private var activeSlot: PassportPhotoSlot?
    @State private var showSourceDialog = false
    @State private var showPhotosPicker = false
    @State private var showCamera = false
    @State private var showDetailSheet = false
    @State private var pickedItem: PhotosPickerItem?
    @State private var didFinish = false

    private var entry: BeautyPassportEntry? { store.passportEntry(with: entryID) }
    private var client: Client? { entry.flatMap { store.client(with: $0.clientID) } }

    private var usedFields: Set<BeautyPassportField> {
        Set(entry?.details.compactMap(\.field) ?? [])
    }

    var body: some View {
        ScrollView {
            if let entry {
                VStack(alignment: .leading, spacing: 22) {
                    visitHeader(entry)
                    photosSection(entry)
                    recipeSection(entry)
                    noteSection
                    finishSection(entry)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            } else {
                ContentUnavailableView("Įrašas nerastas", systemImage: "doc.badge.ellipsis")
                    .padding(.top, 60)
            }
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Grožio pasas")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(Palette.bone, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .onAppear(perform: loadNote)
        .onDisappear(perform: saveNote)
        .confirmationDialog(
            activeSlot.map { "Nuotrauka · \($0.title)" } ?? "Nuotrauka",
            isPresented: $showSourceDialog,
            titleVisibility: .visible
        ) {
            photoSourceButtons
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $pickedItem, matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                apply(image)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showDetailSheet) {
            PassportDetailSheet(usedFields: usedFields) { detail in
                addDetail(detail)
            }
        }
        .task(id: pickedItem) {
            await loadPickedPhoto()
        }
        .task(id: noteText) {
            await autosaveNote()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: entry?.details ?? [])
    }

    // MARK: - Visit header

    private func visitHeader(_ entry: BeautyPassportEntry) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                InitialsAvatar(name: client?.fullName ?? entry.serviceName, size: 48)
                VStack(alignment: .leading, spacing: 3) {
                    Text(client?.fullName ?? "Klientas")
                        .font(.headline)
                        .foregroundStyle(Palette.ink)
                    Text(entry.date.dayText)
                        .font(.caption)
                        .foregroundStyle(Palette.inkSoft)
                }
                Spacer(minLength: 4)
                statusChip(entry)
            }

            Divider().overlay(Palette.hairline)

            HStack(spacing: 10) {
                Label(entry.serviceName, systemImage: entry.category.symbolName)
                Spacer(minLength: 8)
                Label(entry.specialistName, systemImage: "person")
            }
            .font(.caption)
            .foregroundStyle(Palette.inkSoft)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 16)
    }

    private func statusChip(_ entry: BeautyPassportEntry) -> some View {
        Text(entry.isDraft ? "Juodraštis" : "Užbaigta")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(entry.isDraft ? Palette.ink : Palette.forest)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                (entry.isDraft ? Palette.marigold.opacity(0.35) : Palette.eucalyptus.opacity(0.45)),
                in: .capsule
            )
    }

    // MARK: - Photos

    private func photosSection(_ entry: BeautyPassportEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Nuotraukos")

            HStack(alignment: .top, spacing: 12) {
                photoSlot(.before, reference: entry.beforePhoto)
                photoSlot(.after, reference: entry.afterPhoto)
            }
        }
    }

    private func photoSlot(_ slot: PassportPhotoSlot, reference: PassportPhotoReference?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(slot.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.inkSoft)
                .textCase(.uppercase)
                .kerning(0.6)

            Button {
                activeSlot = slot
                showSourceDialog = true
            } label: {
                PassportPhotoView(
                    reference: reference,
                    height: 200,
                    cornerRadius: 18,
                    placeholderSymbol: "camera",
                    placeholderText: "Pridėti nuotrauką"
                )
                .frame(maxWidth: .infinity)
                .overlay(alignment: .bottomTrailing) {
                    if reference != nil {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.ink)
                            .padding(8)
                            .background(Palette.bone.opacity(0.92), in: .circle)
                            .padding(8)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var photoSourceButtons: some View {
        if CameraPicker.isAvailable {
            Button("Fotografuoti") { showCamera = true }
        }
        Button("Pasirinkti iš galerijos") { showPhotosPicker = true }
        if let slot = activeSlot, currentReference(for: slot) != nil {
            Button("Pašalinti nuotrauką", role: .destructive) { removePhoto(from: slot) }
        }
        Button("Atšaukti", role: .cancel) { activeSlot = nil }
    }

    // MARK: - Recipe

    private func recipeSection(_ entry: BeautyPassportEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Receptas")

            VStack(alignment: .leading, spacing: 0) {
                if entry.details.isEmpty {
                    Text("Pridėkite tik tai, kas svarbu šiai paslaugai.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.inkSoft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 14)
                } else {
                    ForEach(Array(entry.details.enumerated()), id: \.element.id) { index, detail in
                        detailRow(detail)
                        if index < entry.details.count - 1 {
                            Divider().overlay(Palette.hairline)
                        }
                    }
                    Divider().overlay(Palette.hairline).padding(.top, 4)
                }

                Button {
                    showDetailSheet = true
                } label: {
                    Label("Pridėti detalę", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.forest)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, entry.details.isEmpty ? 0 : 12)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            .cardSurface(padding: 16)
        }
    }

    private func detailRow(_ detail: BeautyPassportDetail) -> some View {
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

            Spacer(minLength: 4)

            Button {
                removeDetail(detail)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.inkSoft)
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Note

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Specialisto pastaba")

            VStack(alignment: .leading, spacing: 8) {
                TextField("Pastaba kitam vizitui", text: $noteText, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(3...6)

                Text("Vidinė pastaba — klientui nerodoma.")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(padding: 16)
        }
    }

    // MARK: - Finish

    @ViewBuilder
    private func finishSection(_ entry: BeautyPassportEntry) -> some View {
        if entry.isDraft {
            VStack(spacing: 8) {
                Button {
                    finish(entry)
                } label: {
                    Label("Užbaigti Grožio pasą", systemImage: "checkmark.seal")
                }
                .buttonStyle(MarigoldButtonStyle(isDisabled: !entry.hasContent))
                .disabled(!entry.hasContent)
                .sensoryFeedback(.success, trigger: didFinish)

                Text(entry.hasContent
                     ? "Įrašai išsaugomi automatiškai."
                     : "Pridėkite nuotrauką, detalę arba pastabą.")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSoft)
            }
            .padding(.top, 4)
        } else {
            Label("Grožio pasas užbaigtas", systemImage: "checkmark.seal.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.forest)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
    }

    // MARK: - Actions

    private func currentReference(for slot: PassportPhotoSlot) -> PassportPhotoReference? {
        guard let entry else { return nil }
        return slot == .before ? entry.beforePhoto : entry.afterPhoto
    }

    private func apply(_ image: UIImage) {
        guard let slot = activeSlot, var entry else { return }
        guard let reference = PassportPhotoStore.save(image) else { return }

        PassportPhotoStore.remove(currentReference(for: slot))
        switch slot {
        case .before: entry.beforeImageName = reference.storedValue
        case .after: entry.afterImageName = reference.storedValue
        }
        store.savePassportEntry(entry)
        activeSlot = nil
    }

    private func removePhoto(from slot: PassportPhotoSlot) {
        guard var entry else { return }
        PassportPhotoStore.remove(currentReference(for: slot))
        switch slot {
        case .before: entry.beforeImageName = nil
        case .after: entry.afterImageName = nil
        }
        store.savePassportEntry(entry)
        activeSlot = nil
    }

    private func loadPickedPhoto() async {
        guard let pickedItem else { return }
        defer { self.pickedItem = nil }
        do {
            guard let data = try await pickedItem.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }
            apply(image)
        } catch {
            print("[BeautyPassport] Nepavyko įkelti nuotraukos: \(error.localizedDescription)")
        }
    }

    private func addDetail(_ detail: BeautyPassportDetail) {
        guard var entry else { return }
        entry.details.append(detail)
        store.savePassportEntry(entry)
    }

    private func removeDetail(_ detail: BeautyPassportDetail) {
        guard var entry else { return }
        entry.details.removeAll { $0.id == detail.id }
        store.savePassportEntry(entry)
    }

    private func loadNote() {
        guard !didLoadNote else { return }
        noteText = entry?.specialistNote ?? ""
        didLoadNote = true
    }

    /// Autosaves the note a moment after typing stops, so leaving the screen at any
    /// point keeps the text.
    private func autosaveNote() async {
        guard didLoadNote else { return }
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        saveNote()
    }

    private func saveNote() {
        guard didLoadNote, var entry else { return }
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        let updated: String? = trimmed.isEmpty ? nil : trimmed
        guard updated != entry.specialistNote else { return }
        entry.specialistNote = updated
        store.savePassportEntry(entry)
    }

    private func finish(_ entry: BeautyPassportEntry) {
        saveNote()
        guard let latest = store.passportEntry(with: entryID) ?? Optional(entry) else { return }
        store.completePassportEntry(latest)
        didFinish = true
        dismiss()
    }
}

// MARK: - Add detail

/// Picks a recipe field, takes its value, and hands back one finished line.
/// Nothing is required: the specialist adds only what this service actually needs.
private struct PassportDetailSheet: View {
    let usedFields: Set<BeautyPassportField>
    let onAdd: (BeautyPassportDetail) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var field: BeautyPassportField?
    @State private var isCustom = false
    @State private var customTitle = ""
    @State private var value = ""
    @FocusState private var isValueFocused: Bool

    private var canAdd: Bool {
        let hasValue = !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasTitle = isCustom
            ? !customTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            : field != nil
        return hasValue && hasTitle
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Detalės tipas")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.inkSoft)
                        .textCase(.uppercase)
                        .kerning(0.6)

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 130), spacing: 8)],
                        alignment: .leading,
                        spacing: 8
                    ) {
                        ForEach(BeautyPassportField.allCases, id: \.self) { option in
                            chip(
                                title: option.title,
                                symbol: option.symbolName,
                                isSelected: !isCustom && field == option,
                                isUsed: usedFields.contains(option)
                            ) {
                                field = option
                                isCustom = false
                                isValueFocused = true
                            }
                        }
                        chip(title: "Kita", symbol: "sparkles", isSelected: isCustom, isUsed: false) {
                            isCustom = true
                            field = nil
                            isValueFocused = true
                        }
                    }

                    if isCustom {
                        TextField("Pavadinimas", text: $customTitle)
                            .font(.subheadline)
                            .padding(14)
                            .background(Palette.surface, in: .rect(cornerRadius: 14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14).stroke(Palette.hairline, lineWidth: 1)
                            }
                    }

                    TextField("Reikšmė", text: $value, axis: .vertical)
                        .font(.subheadline)
                        .lineLimit(1...4)
                        .focused($isValueFocused)
                        .padding(14)
                        .background(Palette.surface, in: .rect(cornerRadius: 14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14).stroke(Palette.hairline, lineWidth: 1)
                        }

                    Button(action: add) {
                        Text("Pridėti")
                    }
                    .buttonStyle(MarigoldButtonStyle(isDisabled: !canAdd))
                    .disabled(!canAdd)
                }
                .padding(20)
            }
            .background(Palette.bone)
            .scrollIndicators(.hidden)
            .navigationTitle("Nauja detalė")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Atšaukti") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationContentInteraction(.scrolls)
    }

    private func chip(
        title: String,
        symbol: String,
        isSelected: Bool,
        isUsed: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.medium))
                .foregroundStyle(isSelected ? Palette.ink : Palette.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    isSelected ? Palette.marigold.opacity(0.35) : Palette.surface,
                    in: .capsule
                )
                .overlay {
                    Capsule().stroke(
                        isSelected ? Palette.marigold : Palette.hairline,
                        lineWidth: 1
                    )
                }
                .opacity(isUsed && !isSelected ? 0.55 : 1)
        }
        .buttonStyle(.plain)
    }

    private func add() {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if isCustom {
            let title = customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            onAdd(BeautyPassportDetail(title: title, value: trimmedValue))
        } else if let field {
            onAdd(BeautyPassportDetail(field: field, value: trimmedValue))
        }
        dismiss()
    }
}
