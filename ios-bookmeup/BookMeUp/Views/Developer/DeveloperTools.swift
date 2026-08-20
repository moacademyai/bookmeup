import SwiftUI

/// Development-only switches.
///
/// To remove this from a production release: set `isEnabled` to `false`, or delete
/// this file together with its two `DeveloperToolsSection(...)` call sites in
/// `ProfileView` and `WorkspaceView`. Nothing else depends on it.
nonisolated enum DevTools {
    /// Set to `false` before shipping.
    static let isEnabled = true

    /// The same key `ContentView` reads, so the choice survives app restarts on device.
    static let roleStorageKey = "bookmeup.devRole"
}

/// Role switcher placed inside Profile / Settings content. It never floats over the UI
/// and works the same on the simulator and on a physical device development build.
struct DeveloperToolsSection: View {
    /// Matches the surface it sits on: bone profile screens or the pine workspace.
    enum Tone {
        case light
        case dark
    }

    let tone: Tone

    @AppStorage(DevTools.roleStorageKey) private var storedRole: String = AppRole.client.rawValue

    private var currentRole: AppRole { AppRole(rawValue: storedRole) ?? .client }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Kūrėjo įrankiai", onDark: tone == .dark)

            VStack(alignment: .leading, spacing: 0) {
                currentRow

                ForEach(AppRole.availableRoles) { role in
                    divider
                    switchRow(to: role)
                }

                divider

                Text("Šis skydelis skirtas tik testavimui ir bus pašalintas prieš išleidimą. Gamyboje aplinka priklauso nuo prisijungusio vartotojo paskyros, narystės versle ir rolės teisių.")
                    .font(.caption)
                    .foregroundStyle(secondaryColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 12)
            }
            .modifier(DeveloperToolsSurface(tone: tone))
        }
    }

    private var currentRow: some View {
        HStack(spacing: 12) {
            icon("hammer.fill")
            VStack(alignment: .leading, spacing: 2) {
                Text("Dabartinė rolė")
                    .font(.caption)
                    .foregroundStyle(secondaryColor)
                Text(currentRole.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryColor)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
    }

    private func switchRow(to role: AppRole) -> some View {
        let isActive = role == currentRole
        return Button {
            guard !isActive else { return }
            storedRole = role.rawValue
        } label: {
            HStack(spacing: 12) {
                icon(role.symbolName)
                Text("Perjungti į: \(role.title)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isActive ? secondaryColor : primaryColor)
                Spacer(minLength: 8)
                if isActive {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(accentColor)
                }
            }
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isActive)
        .accessibilityLabel("Perjungti į \(role.title)")
    }

    private func icon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.footnote)
            .foregroundStyle(accentColor)
            .frame(width: 32, height: 32)
            .background(accentColor.opacity(tone == .dark ? 0.16 : 0.22), in: .rect(cornerRadius: 10))
    }

    private var divider: some View {
        Divider().overlay(tone == .dark ? Palette.eucalyptus.opacity(0.14) : Palette.hairline)
    }

    private var primaryColor: Color { tone == .dark ? Palette.bone : Palette.ink }
    private var secondaryColor: Color { tone == .dark ? Palette.eucalyptus.opacity(0.75) : Palette.inkSoft }
    private var accentColor: Color { tone == .dark ? Palette.eucalyptus : Palette.forest }
}

/// Keeps the panel on the same card language as the screen hosting it.
private struct DeveloperToolsSurface: ViewModifier {
    let tone: DeveloperToolsSection.Tone

    func body(content: Content) -> some View {
        switch tone {
        case .light:
            content.cardSurface(padding: 16)
        case .dark:
            content
                .padding(16)
                .background(Palette.pineElevated, in: .rect(cornerRadius: 22))
                .overlay {
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Palette.eucalyptus.opacity(0.18), lineWidth: 1)
                }
        }
    }
}
