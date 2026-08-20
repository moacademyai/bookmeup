import SwiftUI

/// How the client app should look.
///
/// Stored as a raw string so the choice survives relaunches, and read in exactly one
/// place — the client tab root — so no screen has to know the setting exists.
nonisolated enum AppearanceSetting: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    /// The single storage key. Anything reading appearance uses this constant.
    static let storageKey = "bookmeup.appearance"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "Pagal sistemą"
        case .light: "Šviesi"
        case .dark: "Tamsi"
        }
    }

    var symbolName: String {
        switch self {
        case .system: "iphone"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }

    /// `nil` follows the device, which is what `.system` means to SwiftUI.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
