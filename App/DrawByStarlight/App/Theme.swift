import SwiftUI
import UIKit

/// Shared visual language: Paint by Moonlight's design system, night side only (the sky is the
/// canvas, so the app is always dark: `UIUserInterfaceStyle` is Dark). New York for titles, names
/// and numerals, SF for the rest; antique gold only for stars, sparkles and the Moon; Nightshade
/// under the one primary button. The asset catalog's colors carry its tokens.
enum Theme {
    /// `surface-base`: screen background, the night sky.
    static let paper = Color("Paper")
    /// `surface-elevated`: cards, sheets, grouped rows.
    static let surface = Color("Surface")
    /// `radius-lg`: cards.
    static let cardRadius: CGFloat = 20
    static let hairline = Color.primary.opacity(0.08)
    /// `tint`: antique gold at night.
    static let accent = Color("AccentColor")
    /// `nightshade`, the signature: under the labels of primary buttons.
    static let signature = Color(red: 0.482, green: 0.247, blue: 0.494)
    /// `pot-3-gold`, the only color of stars, sparkles and the Moon.
    static let gold = Color(red: 0.788, green: 0.635, blue: 0.290)
    /// `outline`: line work and hairlines.
    static let outline = Color("Outline")
    /// Parchment: the drawn lines and the stars' names, and the faint stars around a figure.
    static let ink = Color(red: 0.929, green: 0.902, blue: 0.855)
    /// Lavender, for what's only a hint: a line that didn't belong, a border, a note.
    static let lavender = Color(red: 0.608, green: 0.541, blue: 0.706)
    /// The gold's light: a star's heart and the glimmer.
    static let goldLight = Color(red: 0.929, green: 0.816, blue: 0.537)

    /// Navigation titles in New York, like the identity's headings.
    static func styleNavigationTitles() {
        let bar = UINavigationBar.appearance()
        bar.largeTitleTextAttributes = [.font: serifFont(.largeTitle, size: 34, weight: .bold)]
        bar.titleTextAttributes = [.font: serifFont(.headline, size: 17, weight: .semibold)]
    }

    /// `size` is the style's size at the default text size; the font scales from it.
    private static func serifFont(_ style: UIFont.TextStyle, size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let system = UIFont.systemFont(ofSize: size, weight: weight)
        let serif = system.fontDescriptor.withDesign(.serif).map { UIFont(descriptor: $0, size: size) } ?? system
        return UIFontMetrics(forTextStyle: style).scaledFont(for: serif)
    }
}

extension Font {
    /// New York (the system serif) at a Dynamic Type style: titles, names and numerals.
    static func display(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .serif, weight: weight)
    }
}
