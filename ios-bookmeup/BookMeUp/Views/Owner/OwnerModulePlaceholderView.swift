import SwiftUI

/// The screen of a module whose foundation exists but whose UI does not.
///
/// It is deliberately not an empty page: it names what will live here, which permission
/// opens it and which layer it belongs to. That way the information architecture is
/// already usable and reviewable before a single feature behind it is written — and no
/// screen is padded with invented data to look finished.
struct OwnerModulePlaceholderView: View {
    let module: OwnerModule

    @Environment(BusinessStore.self) private var business

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                if !module.plannedContent.isEmpty {
                    OwnerSection(title: "Kas čia bus") {
                        SettingsGroup {
                            ForEach(Array(module.plannedContent.enumerated()), id: \.element) { index, line in
                                HStack(alignment: .top, spacing: 12) {
                                    Circle()
                                        .fill(Palette.eucalyptus)
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 7)
                                    Text(line)
                                        .font(.subheadline)
                                        .foregroundStyle(Palette.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)
                                if index < module.plannedContent.count - 1 {
                                    Divider().overlay(Palette.hairline).padding(.leading, 32)
                                }
                            }
                        }
                    }
                }

                OwnerSection(title: "Prieiga") {
                    SettingsGroup {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Palette.forest)
                                .frame(width: 34, height: 34)
                                .background(Palette.eucalyptus.opacity(0.35), in: .rect(cornerRadius: 11))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(module.permission.title)
                                    .font(.subheadline)
                                    .foregroundStyle(Palette.ink)
                                Text("Šią skiltį atidaro ši teisė")
                                    .font(.caption)
                                    .foregroundStyle(Palette.inkSoft)
                            }
                            Spacer(minLength: 8)
                            OwnerStatusBadge(
                                text: business.can(module.permission) ? "Turi" : "Neturi",
                                tone: business.can(module.permission) ? .positive : .critical
                            )
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(minHeight: 56)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle(module.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Palette.bone, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: module.symbolName)
                    .font(.headline)
                    .foregroundStyle(Palette.forest)
                    .frame(width: 44, height: 44)
                    .background(Palette.eucalyptus.opacity(0.35), in: .circle)
                VStack(alignment: .leading, spacing: 3) {
                    Text(module.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Palette.ink)
                    Text("\(module.area.title) · \(module.readiness.title)")
                        .font(.caption)
                        .foregroundStyle(Palette.inkSoft)
                }
                Spacer(minLength: 0)
            }

            Text(module.subtitle)
                .font(.subheadline)
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            Text("Duomenų modelis ir vieta navigacijoje jau paruošti. Ekranas bus įjungtas nekeičiant pagrindinės navigacijos.")
                .font(.footnote)
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 16)
        .padding(.top, 6)
    }
}
