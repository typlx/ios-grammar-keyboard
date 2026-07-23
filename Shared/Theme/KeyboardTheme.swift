import UIKit

public enum ThemePreset: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case amoledBlack = "amoled_black"
    case highContrast = "high_contrast"
    case custom = "custom"

    public var displayName: String {
        switch self {
        case .system: return "System (Auto)"
        case .light: return "Light"
        case .dark: return "Dark"
        case .amoledBlack: return "AMOLED Black"
        case .highContrast: return "High Contrast"
        case .custom: return "Custom"
        }
    }
}

public struct KeyboardTheme {
    public let keyBackground: UIColor
    public let keyText: UIColor
    public let keyboardBackground: UIColor
    public let accent: UIColor
    public let toolbarBackground: UIColor

    public static let light = KeyboardTheme(
        keyBackground: .white,
        keyText: .black,
        keyboardBackground: UIColor(white: 0.82, alpha: 1),
        accent: .systemBlue,
        toolbarBackground: .systemGroupedBackground
    )

    public static let dark = KeyboardTheme(
        keyBackground: UIColor(white: 0.30, alpha: 1),
        keyText: .white,
        keyboardBackground: UIColor(white: 0.17, alpha: 1),
        accent: UIColor(red: 0.24, green: 0.55, blue: 0.95, alpha: 1),
        toolbarBackground: UIColor(white: 0.13, alpha: 1)
    )

    public static let amoledBlack = KeyboardTheme(
        keyBackground: UIColor(white: 0.12, alpha: 1),
        keyText: .white,
        keyboardBackground: .black,
        accent: UIColor(red: 0.24, green: 0.55, blue: 0.95, alpha: 1),
        toolbarBackground: UIColor(white: 0.07, alpha: 1)
    )

    public static let highContrast = KeyboardTheme(
        keyBackground: .white,
        keyText: .black,
        keyboardBackground: .black,
        accent: UIColor(red: 1.0, green: 0.84, blue: 0, alpha: 1),
        toolbarBackground: .black
    )
}
