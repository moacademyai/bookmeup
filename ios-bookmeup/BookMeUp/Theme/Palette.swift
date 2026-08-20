import SwiftUI
import UIKit

/// The BookMeUp color system.
///
/// These are semantic tokens, not literal colors: `bone` means "the app canvas" and
/// `ink` means "primary text", each resolving to a different value in light and dark.
/// That is what makes dark mode a real theme rather than an inversion — the warm bone
/// canvas becomes a warm near-black, the deep forest green becomes a lighter sage that
/// still reads as the same brand, and marigold stays the one accent that says "act".
///
/// Fixed tokens (`pine`, `pineElevated`, `onPine`) are deliberately not adaptive: they
/// are the dark surfaces the specialist workspace is built from, and text placed on them
/// must stay light in both appearances.
nonisolated enum Palette {

    // MARK: - Canvas and surfaces

    /// The app background.
    static let bone = adaptive(light: 0xF6F3E8, dark: 0x141311)
    /// Cards and rows sitting on the canvas.
    static let surface = adaptive(light: 0xFFFDF7, dark: 0x1D1B17)
    /// A surface that needs to sit above another surface — sheets, popovers, map cards.
    static let elevated = adaptive(light: 0xFFFFFF, dark: 0x262320)

    // MARK: - Text

    /// Primary text.
    static let ink = adaptive(light: 0x16241F, dark: 0xF3EEE2)
    /// Secondary text: captions, supporting lines, inactive states.
    static let inkSoft = adaptive(light: 0x16241F, dark: 0xF3EEE2, lightOpacity: 0.62, darkOpacity: 0.60)
    /// Hairline borders and dividers.
    static let hairline = adaptive(light: 0x16241F, dark: 0xF3EEE2, lightOpacity: 0.09, darkOpacity: 0.15)

    // MARK: - Brand

    /// The primary brand green: quiet, used for structure and trust.
    static let forest = adaptive(light: 0x2F5D4E, dark: 0x7FBFA3)
    /// The tinted background behind forest icons and chips.
    static let eucalyptus = adaptive(light: 0xBFD8CB, dark: 0x2C4239)
    /// The one warm accent. Reserved for the primary action on a screen.
    static let marigold = adaptive(light: 0xE7A84B, dark: 0xE9AE58)

    // MARK: - Status

    static let success = adaptive(light: 0x3E7D5A, dark: 0x76C79B)
    static let warning = adaptive(light: 0xC98A2E, dark: 0xE3B063)
    /// Cancellations, destructive actions.
    static let terracotta = adaptive(light: 0xD96F5B, dark: 0xE38270)
    static var danger: Color { terracotta }

    // MARK: - Fixed dark surfaces

    /// The specialist workspace background. Dark in both appearances by design.
    static let pine = Color(hex: 0x10201D)
    static let pineElevated = Color(hex: 0x1B302B)
    /// Text and icons placed on `pine`. Always light — never use `bone` for this.
    static let onPine = Color(hex: 0xF6F3E8)

    /// Builds a token that resolves per appearance.
    private static func adaptive(
        light: UInt32,
        dark: UInt32,
        lightOpacity: Double = 1,
        darkOpacity: Double = 1
    ) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark, alpha: darkOpacity)
                : UIColor(hex: light, alpha: lightOpacity)
        })
    }
}

nonisolated extension Color {
    /// Creates a color from a 24-bit RGB literal, e.g. `Color(hex: 0xF6F3E8)`.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

nonisolated extension UIColor {
    convenience init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: CGFloat(alpha)
        )
    }
}
