import XCTest
@testable import TypistKeyboard

/// Tests that verify all keyboard settings survive a simulated app restart by reading
/// back from AppGroupConfig's sharedDefaults — the same UserDefaults suite the container
/// app and keyboard extension share via their App Group entitlement.
final class SettingsPersistenceTests: XCTestCase {

    // Keys under test in this file.
    private let keysToClean: [AppGroupConfig.DefaultsKey] = [
        .selectedProvider, .openAIModel, .anthropicModel,
        .openAIURL, .anthropicURL, .processingMode,
        .defaultContext, .language, .autocorrectEnabled,
        .hapticFeedbackEnabled, .wordSuggestionsEnabled,
    ]

    override func setUp() {
        super.setUp()
        removeAllTestKeys()
    }

    override func tearDown() {
        removeAllTestKeys()
        super.tearDown()
    }

    private func removeAllTestKeys() {
        for key in keysToClean {
            AppGroupConfig.sharedDefaults.removeObject(forKey: key.rawValue)
        }
    }

    // MARK: - Bool settings round-trip

    func testWordSuggestionsEnabledPersistsRoundtrip() {
        AppGroupConfig.set(false, for: .wordSuggestionsEnabled)
        XCTAssertFalse(AppGroupConfig.bool(for: .wordSuggestionsEnabled, defaultValue: true),
                       "wordSuggestionsEnabled=false must persist and override the default=true")
    }

    func testWordSuggestionsEnabledTrueRoundtrip() {
        AppGroupConfig.set(true, for: .wordSuggestionsEnabled)
        XCTAssertTrue(AppGroupConfig.bool(for: .wordSuggestionsEnabled, defaultValue: false),
                      "wordSuggestionsEnabled=true must persist and override the default=false")
    }

    func testHapticFeedbackDisabledPersists() {
        AppGroupConfig.set(false, for: .hapticFeedbackEnabled)
        XCTAssertFalse(AppGroupConfig.bool(for: .hapticFeedbackEnabled, defaultValue: true),
                       "hapticFeedbackEnabled=false must survive being read back")
    }

    func testAutocorrectEnabledFalsePersists() {
        AppGroupConfig.set(false, for: .autocorrectEnabled)
        XCTAssertFalse(AppGroupConfig.bool(for: .autocorrectEnabled, defaultValue: true))
    }

    // MARK: - String settings round-trip

    func testLanguageSettingPersistsRoundtrip() {
        AppGroupConfig.set(CorrectionLanguage.french.rawValue, for: .language)
        XCTAssertEqual(AppGroupConfig.string(for: .language), "fr",
                       "Language setting must survive write → read")
    }

    func testDefaultContextPersistsRoundtrip() {
        AppGroupConfig.set(ContextType.email.rawValue, for: .defaultContext)
        XCTAssertEqual(AppGroupConfig.string(for: .defaultContext), "email",
                       "defaultContext setting must survive write → read")
    }

    func testProcessingModeSettingPersistsRoundtrip() {
        AppGroupConfig.set("cloud", for: .processingMode)
        XCTAssertEqual(AppGroupConfig.string(for: .processingMode), "cloud",
                       "processingMode setting must survive write → read")
    }

    func testSelectedProviderPersistsRoundtrip() {
        AppGroupConfig.set(ProviderType.anthropic.rawValue, for: .selectedProvider)
        XCTAssertEqual(AppGroupConfig.string(for: .selectedProvider), "anthropic")
    }

    // MARK: - Overwrite semantics

    func testSettingCanBeOverwrittenMultipleTimes() {
        AppGroupConfig.set(CorrectionLanguage.english.rawValue, for: .language)
        AppGroupConfig.set(CorrectionLanguage.spanish.rawValue, for: .language)
        AppGroupConfig.set(CorrectionLanguage.german.rawValue, for: .language)
        XCTAssertEqual(AppGroupConfig.string(for: .language), "de",
                       "Final write must win when the same key is overwritten multiple times")
    }

    func testRemovingObjectRevokesStringToNil() {
        AppGroupConfig.set("fr", for: .language)
        AppGroupConfig.sharedDefaults.removeObject(forKey: AppGroupConfig.DefaultsKey.language.rawValue)
        XCTAssertNil(AppGroupConfig.string(for: .language),
                     "Removing the object must cause the string accessor to return nil")
    }

    func testRemovingObjectRevokesBoolToDefaultValue() {
        AppGroupConfig.set(false, for: .wordSuggestionsEnabled)
        AppGroupConfig.sharedDefaults.removeObject(forKey: AppGroupConfig.DefaultsKey.wordSuggestionsEnabled.rawValue)
        // After removal the key is absent, so the configured defaultValue must be returned.
        XCTAssertTrue(AppGroupConfig.bool(for: .wordSuggestionsEnabled, defaultValue: true),
                      "After removing a bool key, the defaultValue must be returned")
    }

    // MARK: - Multiple independent settings survive together

    func testMultipleSettingsSurviveIndependentReads() {
        AppGroupConfig.set(ProviderType.anthropic.rawValue, for: .selectedProvider)
        AppGroupConfig.set(CorrectionLanguage.french.rawValue, for: .language)
        AppGroupConfig.set(false, for: .hapticFeedbackEnabled)

        // Read all three back; each must return its own stored value.
        XCTAssertEqual(AppGroupConfig.string(for: .selectedProvider), "anthropic")
        XCTAssertEqual(AppGroupConfig.string(for: .language), "fr")
        XCTAssertFalse(AppGroupConfig.bool(for: .hapticFeedbackEnabled, defaultValue: true))
    }

    // MARK: - Absent keys return correct defaults

    func testAbsentWordSuggestionsEnabledReturnsDefaultTrue() {
        XCTAssertTrue(AppGroupConfig.bool(for: .wordSuggestionsEnabled, defaultValue: true),
                      "Unset wordSuggestionsEnabled must return the supplied defaultValue")
    }

    func testAbsentLanguageReturnsNil() {
        XCTAssertNil(AppGroupConfig.string(for: .language),
                     "Unset language key must return nil, not an empty string")
    }
}
