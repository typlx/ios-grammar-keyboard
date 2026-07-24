import UIKit

public final class ThemeManager {
    public static let shared = ThemeManager()
    private init() {}

    public var selectedPreset: ThemePreset {
        get {
            let raw = AppGroupConfig.string(for: .themePreset) ?? ThemePreset.system.rawValue
            return ThemePreset(rawValue: raw) ?? .system
        }
        set {
            AppGroupConfig.set(newValue.rawValue, for: .themePreset)
        }
    }

    public var customKeyBackground: UIColor {
        get { storedColor(for: .customKeyBackground) ?? .white }
        set { store(newValue, for: .customKeyBackground) }
    }

    public var customKeyText: UIColor {
        get { storedColor(for: .customKeyText) ?? .black }
        set { store(newValue, for: .customKeyText) }
    }

    public var customAccent: UIColor {
        get { storedColor(for: .customAccent) ?? .systemBlue }
        set { store(newValue, for: .customAccent) }
    }

    public func resolvedTheme(for traitCollection: UITraitCollection) -> KeyboardTheme {
        switch selectedPreset {
        case .system:
            return traitCollection.userInterfaceStyle == .dark ? .dark : .light
        case .light:
            return .light
        case .dark:
            return .dark
        case .amoledBlack:
            return .amoledBlack
        case .highContrast:
            return .highContrast
        case .custom:
            return KeyboardTheme(
                keyBackground: customKeyBackground,
                keyText: customKeyText,
                keyboardBackground: UIColor(white: 0.82, alpha: 1),
                accent: customAccent,
                toolbarBackground: .systemGroupedBackground
            )
        }
    }

    private func storedColor(for key: AppGroupConfig.DefaultsKey) -> UIColor? {
        guard let hex = AppGroupConfig.string(for: key) else { return nil }
        return UIColor(hexString: hex)
    }

    private func store(_ color: UIColor, for key: AppGroupConfig.DefaultsKey) {
        AppGroupConfig.set(color.hexString, for: key)
    }
}

extension UIColor {
    convenience init?(hexString: String) {
        guard hexString.hasPrefix("#"), hexString.count == 7 else { return nil }
        let hex = String(hexString.dropFirst())
        guard let value = UInt64(hex, radix: 16) else { return nil }
        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >> 8) & 0xFF) / 255
        let b = CGFloat(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }

    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: nil)
        return String(format: "#%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
    }
}
