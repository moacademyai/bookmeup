import SwiftUI

/// „Nustatymai“.
///
/// Native in feel, BookMeUp in language. Only settings that actually do something appear
/// here — a screen padded out with rows that lead nowhere is worse than a short one.
struct SettingsView: View {
    @AppStorage(AppearanceSetting.storageKey) private var storedAppearance = AppearanceSetting.system.rawValue

    private var appearance: AppearanceSetting {
        AppearanceSetting(rawValue: storedAppearance) ?? .system
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                appearanceSection

                ProfileRowGroup {
                    ProfileRow(title: "Apie BookMeUp", symbolName: "info.circle") {
                        AboutView()
                    }
                }

                if DevTools.isEnabled {
                    DeveloperToolsSection(tone: .light)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle("Nustatymai")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(Palette.bone, for: .navigationBar)
    }

    /// The one setting that changes how the whole client app looks.
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Išvaizda")
            VStack(spacing: 0) {
                ForEach(AppearanceSetting.allCases) { option in
                    appearanceRow(option)
                    if option != AppearanceSetting.allCases.last {
                        ProfileRowDivider()
                    }
                }
            }
            .cardSurface(padding: 16)
        }
    }

    private func appearanceRow(_ option: AppearanceSetting) -> some View {
        let isSelected = appearance == option
        return Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                storedAppearance = option.rawValue
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: option.symbolName)
                    .font(.footnote)
                    .foregroundStyle(Palette.forest)
                    .frame(width: 34, height: 34)
                    .background(Palette.eucalyptus.opacity(0.4), in: .rect(cornerRadius: 10))
                Text(option.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Palette.ink)
                Spacer(minLength: 8)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Palette.forest)
                }
            }
            .frame(minHeight: 44)
            .padding(.vertical, 6)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

/// „Apie BookMeUp“ — the short version.
struct AboutView: View {
    private var version: String {
        let bundle = Bundle.main
        let short = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("BookMeUp")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Palette.ink)
                    Text("Pasakykite, ko Jums reikia — laiką surasime mes.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardSurface(padding: 16)

                ProfileRowGroup {
                    HStack {
                        Text("Versija")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Palette.ink)
                        Spacer(minLength: 8)
                        Text(version)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Palette.inkSoft)
                    }
                    .frame(minHeight: 44)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .background(Palette.bone)
        .scrollIndicators(.hidden)
        .navigationTitle("Apie BookMeUp")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(Palette.bone, for: .navigationBar)
    }
}
