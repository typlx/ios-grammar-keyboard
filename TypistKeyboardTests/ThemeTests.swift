import XCTest
import UIKit
@testable import TypistKeyboard

final class ThemeTests: XCTestCase {

    // MARK: - setUp / tearDown

    private var savedPreset: ThemePreset!
    private var savedKeyBackground: String?
    private var savedKeyText: String?
    private var savedAccent: String?

    override func setUp() {
        super.setUp()
        savedPreset = ThemeManager.shared.selectedPreset
        savedKeyBackground = AppGroupConfig.string(for: .customKeyBackground)
        savedKeyText = AppGroupConfig.string(for: .customKeyText)
        savedAccent = AppGroupConfig.string(for: .customAccent)
    }

    override func tearDown() {
        ThemeManager.shared.selectedPreset = savedPreset
        if let v = savedKeyBackground { AppGroupConfig.set(v, for: .customKeyBackground) }
        else { AppGroupConfig.sharedDefaults.removeObject(forKey: AppGroupConfig.DefaultsKey.customKeyBackground.rawValue) }
        if let v = savedKeyText { AppGroupConfig.set(v, for: .customKeyText) }
        else { AppGroupConfig.sharedDefaults.removeObject(forKey: AppGroupConfig.DefaultsKey.customKeyText.rawValue) }
        if let v = savedAccent { AppGroupConfig.set(v, for: .customAccent) }
        else { AppGroupConfig.sharedDefaults.removeObject(forKey: AppGroupConfig.DefaultsKey.customAccent.rawValue) }
        super.tearDown()
    }

    // MARK: - UIColor(hexString:) init — valid inputs

    func testHexInitWhite() {
        let color = UIColor(hexString: "#FFFFFF")
        XCTAssertNotNil(color)
        assertRGB(color!, r: 1, g: 1, b: 1)
    }

    func testHexInitBlack() {
        let color = UIColor(hexString: "#000000")
        XCTAssertNotNil(color)
        assertRGB(color!, r: 0, g: 0, b: 0)
    }

    func testHexInitRed() {
        let color = UIColor(hexString: "#FF0000")
        XCTAssertNotNil(color)
        assertRGB(color!, r: 1, g: 0, b: 0)
    }

    func testHexInitMixedCase() {
        // Lowercase hex digits must be accepted because UInt64(hex, radix:16) is case-insensitive
        let color = UIColor(hexString: "#ff8800")
        XCTAssertNotNil(color)
        assertRGB(color!, r: 1, g: 0.533, b: 0, accuracy: 0.005)
    }

    // MARK: - UIColor(hexString:) init — invalid inputs

    func testHexInitNilWhenMissingHash() {
        XCTAssertNil(UIColor(hexString: "FFFFFF"))
    }

    func testHexInitNilWhenTooShort() {
        XCTAssertNil(UIColor(hexString: "#FFFFF"))
    }

    func testHexInitNilWhenTooLong() {
        XCTAssertNil(UIColor(hexString: "#FFFFFFF"))
    }

    func testHexInitNilWhenHashOnly() {
        XCTAssertNil(UIColor(hexString: "#"))
    }

    func testHexInitNilWhenEmpty() {
        XCTAssertNil(UIColor(hexString: ""))
    }

    func testHexInitNilWhenInvalidCharsGG() {
        XCTAssertNil(UIColor(hexString: "#GGGGGG"))
    }

    // MARK: - UIColor.hexString — round-trip

    func testHexRoundTripWhite() {
        XCTAssertEqual(UIColor(red: 1, green: 1, blue: 1, alpha: 1).hexString, "#FFFFFF")
    }

    func testHexRoundTripBlack() {
        XCTAssertEqual(UIColor(red: 0, green: 0, blue: 0, alpha: 1).hexString, "#000000")
    }

    func testHexRoundTripArbitraryColor() {
        let hex = "#AB4F12"
        let color = UIColor(hexString: hex)!
        XCTAssertEqual(color.hexString, hex)
    }

    func testHexRoundTripAllPrimaryAndBoundaryColors() {
        for hex in ["#000000", "#FF0000", "#00FF00", "#0000FF", "#FFFFFF", "#7F7F7F"] {
            let color = UIColor(hexString: hex)
            XCTAssertNotNil(color, "UIColor(hexString:) returned nil for \(hex)")
            XCTAssertEqual(color!.hexString, hex, "Round-trip failed for \(hex)")
        }
    }

    func testHexStringIsUppercase() {
        // hexString must always emit uppercase letters (A–F not a–f)
        let color = UIColor(hexString: "#aabbcc")!
        let result = color.hexString
        XCTAssertEqual(result, result.uppercased())
    }

    // MARK: - ThemePreset.displayName

    func testDisplayNameSystem() {
        XCTAssertEqual(ThemePreset.system.displayName, "System (Auto)")
    }

    func testDisplayNameLight() {
        XCTAssertEqual(ThemePreset.light.displayName, "Light")
    }

    func testDisplayNameDark() {
        XCTAssertEqual(ThemePreset.dark.displayName, "Dark")
    }

    func testDisplayNameAmoledBlack() {
        XCTAssertEqual(ThemePreset.amoledBlack.displayName, "AMOLED Black")
    }

    func testDisplayNameHighContrast() {
        XCTAssertEqual(ThemePreset.highContrast.displayName, "High Contrast")
    }

    func testDisplayNameCustom() {
        XCTAssertEqual(ThemePreset.custom.displayName, "Custom")
    }

    func testAllPresetsHaveNonEmptyDisplayName() {
        for preset in ThemePreset.allCases {
            XCTAssertFalse(preset.displayName.isEmpty, "displayName empty for .\(preset)")
        }
    }

    // MARK: - ThemeManager.resolvedTheme(for:) — non-system presets ignore trait

    func testLightPresetReturnsSameLightThemeRegardlessOfTrait() {
        ThemeManager.shared.selectedPreset = .light
        let themeInLightMode = ThemeManager.shared.resolvedTheme(for: UITraitCollection(userInterfaceStyle: .light))
        let themeInDarkMode  = ThemeManager.shared.resolvedTheme(for: UITraitCollection(userInterfaceStyle: .dark))
        assertColorsEqual(themeInLightMode.keyBackground, themeInDarkMode.keyBackground)
        assertColorsEqual(themeInLightMode.keyBackground, .white)
        assertColorsEqual(themeInLightMode.keyText, .black)
    }

    func testDarkPresetReturnsDarkThemeRegardlessOfTrait() {
        ThemeManager.shared.selectedPreset = .dark
        let theme = ThemeManager.shared.resolvedTheme(for: UITraitCollection(userInterfaceStyle: .light))
        assertColorsEqual(theme.keyText, .white)
        assertColorsEqual(theme.keyboardBackground, UIColor(white: 0.17, alpha: 1))
        assertColorsEqual(theme.keyBackground, UIColor(white: 0.30, alpha: 1))
    }

    func testAmoledBlackPresetReturnsCorrectTheme() {
        ThemeManager.shared.selectedPreset = .amoledBlack
        let theme = ThemeManager.shared.resolvedTheme(for: UITraitCollection(userInterfaceStyle: .light))
        assertColorsEqual(theme.keyboardBackground, .black)
        assertColorsEqual(theme.keyText, .white)
        assertColorsEqual(theme.keyBackground, UIColor(white: 0.12, alpha: 1))
    }

    func testHighContrastPresetReturnsCorrectTheme() {
        ThemeManager.shared.selectedPreset = .highContrast
        let theme = ThemeManager.shared.resolvedTheme(for: UITraitCollection(userInterfaceStyle: .dark))
        assertColorsEqual(theme.keyBackground, .white)
        assertColorsEqual(theme.keyText, .black)
        assertColorsEqual(theme.keyboardBackground, .black)
    }

    // MARK: - ThemeManager.resolvedTheme(for:) — system preset follows trait

    func testSystemPresetFollowsLightTrait() {
        ThemeManager.shared.selectedPreset = .system
        let theme = ThemeManager.shared.resolvedTheme(for: UITraitCollection(userInterfaceStyle: .light))
        assertColorsEqual(theme.keyBackground, .white)
        assertColorsEqual(theme.keyText, .black)
    }

    func testSystemPresetFollowsDarkTrait() {
        ThemeManager.shared.selectedPreset = .system
        let theme = ThemeManager.shared.resolvedTheme(for: UITraitCollection(userInterfaceStyle: .dark))
        assertColorsEqual(theme.keyText, .white)
        assertColorsEqual(theme.keyboardBackground, UIColor(white: 0.17, alpha: 1))
    }

    // MARK: - ThemeManager.resolvedTheme(for:) — custom preset

    func testCustomPresetUsesStoredKeyBackgroundColor() {
        ThemeManager.shared.selectedPreset = .custom
        ThemeManager.shared.customKeyBackground = UIColor(hexString: "#FF3300")!
        let theme = ThemeManager.shared.resolvedTheme(for: UITraitCollection(userInterfaceStyle: .light))
        assertColorsEqual(theme.keyBackground, UIColor(hexString: "#FF3300")!)
    }

    func testCustomPresetUsesStoredKeyTextColor() {
        ThemeManager.shared.selectedPreset = .custom
        ThemeManager.shared.customKeyText = UIColor(hexString: "#00CCFF")!
        let theme = ThemeManager.shared.resolvedTheme(for: UITraitCollection(userInterfaceStyle: .light))
        assertColorsEqual(theme.keyText, UIColor(hexString: "#00CCFF")!)
    }

    func testCustomPresetUsesStoredAccentColor() {
        ThemeManager.shared.selectedPreset = .custom
        ThemeManager.shared.customAccent = UIColor(hexString: "#FFAA00")!
        let theme = ThemeManager.shared.resolvedTheme(for: UITraitCollection(userInterfaceStyle: .light))
        assertColorsEqual(theme.accent, UIColor(hexString: "#FFAA00")!)
    }

    // MARK: - Helpers

    private func assertRGB(_ color: UIColor, r: CGFloat, g: CGFloat, b: CGFloat,
                           accuracy: CGFloat = 0.004,
                           file: StaticString = #file, line: UInt = #line) {
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        color.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        XCTAssertEqual(ar, r, accuracy: accuracy, "Red", file: file, line: line)
        XCTAssertEqual(ag, g, accuracy: accuracy, "Green", file: file, line: line)
        XCTAssertEqual(ab, b, accuracy: accuracy, "Blue", file: file, line: line)
    }

    private func assertColorsEqual(_ a: UIColor, _ b: UIColor,
                                   accuracy: CGFloat = 0.004,
                                   file: StaticString = #file, line: UInt = #line) {
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        XCTAssertEqual(ar, br, accuracy: accuracy, "Red mismatch", file: file, line: line)
        XCTAssertEqual(ag, bg, accuracy: accuracy, "Green mismatch", file: file, line: line)
        XCTAssertEqual(ab, bb, accuracy: accuracy, "Blue mismatch", file: file, line: line)
    }
}
