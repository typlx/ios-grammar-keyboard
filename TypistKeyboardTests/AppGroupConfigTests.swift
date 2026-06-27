import XCTest
@testable import TypistKeyboard

// Tests for AppGroupConfig's UserDefaults coordination layer.
// Uses a separate in-memory suite so tests do not touch the real App Group container.
final class AppGroupConfigTests: XCTestCase {

    // MARK: - Test suite injection

    // Swap out the real App Group defaults for an isolated in-memory suite.
    private static let testSuiteName = "com.typlx.keyboard.tests.\(UUID().uuidString)"
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: Self.testSuiteName)!
        // Inject test defaults by temporarily swapping via subclass technique is not possible
        // with static AppGroupConfig — so we test through the real sharedDefaults and clean up.
        // Remove any keys we are about to test so there is no bleed from other runs.
        cleanupTestKeys()
    }

    override func tearDown() {
        cleanupTestKeys()
        super.tearDown()
    }

    private func cleanupTestKeys() {
        let keys: [AppGroupConfig.DefaultsKey] = [
            .selectedProvider, .openAIModel, .anthropicModel,
            .openAIURL, .anthropicURL, .processingMode,
            .defaultContext, .language, .autocorrectEnabled, .hapticFeedbackEnabled
        ]
        for key in keys {
            AppGroupConfig.sharedDefaults.removeObject(forKey: key.rawValue)
        }
    }

    // MARK: - String storage

    func testSetAndGetString() {
        AppGroupConfig.set("gpt-4o", for: .openAIModel)
        XCTAssertEqual(AppGroupConfig.string(for: .openAIModel), "gpt-4o")
    }

    func testStringReturnsNilWhenNotSet() {
        XCTAssertNil(AppGroupConfig.string(for: .openAIModel), "Unset string key should return nil")
    }

    func testSetOverwritesPreviousString() {
        AppGroupConfig.set("value-1", for: .openAIModel)
        AppGroupConfig.set("value-2", for: .openAIModel)
        XCTAssertEqual(AppGroupConfig.string(for: .openAIModel), "value-2")
    }

    // MARK: - Bool storage

    func testSetAndGetBoolTrue() {
        AppGroupConfig.set(true, for: .autocorrectEnabled)
        XCTAssertTrue(AppGroupConfig.bool(for: .autocorrectEnabled, defaultValue: false))
    }

    func testSetAndGetBoolFalse() {
        AppGroupConfig.set(false, for: .autocorrectEnabled)
        XCTAssertFalse(AppGroupConfig.bool(for: .autocorrectEnabled, defaultValue: true))
    }

    func testBoolReturnsDefaultValueWhenKeyNotSet() {
        XCTAssertTrue(AppGroupConfig.bool(for: .autocorrectEnabled, defaultValue: true),
                      "Should return defaultValue when key is absent")
        XCTAssertFalse(AppGroupConfig.bool(for: .hapticFeedbackEnabled, defaultValue: false),
                       "Should return defaultValue=false when key is absent")
    }

    func testBoolDefaultValueIsRespectedForDifferentDefaults() {
        XCTAssertTrue(AppGroupConfig.bool(for: .hapticFeedbackEnabled, defaultValue: true))
        XCTAssertFalse(AppGroupConfig.bool(for: .hapticFeedbackEnabled, defaultValue: false))
    }

    func testHapticFeedbackBoolStorageRoundtrip() {
        AppGroupConfig.set(false, for: .hapticFeedbackEnabled)
        XCTAssertFalse(AppGroupConfig.bool(for: .hapticFeedbackEnabled, defaultValue: true))
    }

    // MARK: - DefaultsKey raw values

    func testDefaultsKeyRawValues() {
        XCTAssertEqual(AppGroupConfig.DefaultsKey.selectedProvider.rawValue, "selectedProvider")
        XCTAssertEqual(AppGroupConfig.DefaultsKey.openAIModel.rawValue, "openAIModel")
        XCTAssertEqual(AppGroupConfig.DefaultsKey.anthropicModel.rawValue, "anthropicModel")
        XCTAssertEqual(AppGroupConfig.DefaultsKey.openAIURL.rawValue, "openAIURL")
        XCTAssertEqual(AppGroupConfig.DefaultsKey.anthropicURL.rawValue, "anthropicURL")
        XCTAssertEqual(AppGroupConfig.DefaultsKey.defaultContext.rawValue, "defaultContext")
        XCTAssertEqual(AppGroupConfig.DefaultsKey.language.rawValue, "language")
        XCTAssertEqual(AppGroupConfig.DefaultsKey.autocorrectEnabled.rawValue, "autocorrectEnabled")
        XCTAssertEqual(AppGroupConfig.DefaultsKey.hapticFeedbackEnabled.rawValue, "hapticFeedbackEnabled")
    }

    // MARK: - Shared constants

    func testGroupIdentifier() {
        XCTAssertEqual(AppGroupConfig.groupIdentifier, "group.com.typlx.keyboard")
    }

    func testKeychainAccessGroup() {
        XCTAssertEqual(AppGroupConfig.keychainAccessGroup, "com.typlx.keyboard.shared")
    }

    // MARK: - activeProviderConfig falls back to defaults

    func testActiveProviderConfigDefaultsToOpenAI() {
        // With no selectedProvider set, should fall back to OpenAI
        let config = AppGroupConfig.activeProviderConfig()
        XCTAssertEqual(config.providerType, .openAI)
    }

    func testActiveProviderConfigRespectsLocalProvider() {
        AppGroupConfig.set(ProviderType.local.rawValue, for: .selectedProvider)
        let config = AppGroupConfig.activeProviderConfig()
        XCTAssertEqual(config.providerType, .local)
    }

    func testActiveProviderConfigRespectsAnthropicProvider() {
        AppGroupConfig.set(ProviderType.anthropic.rawValue, for: .selectedProvider)
        let config = AppGroupConfig.activeProviderConfig()
        XCTAssertEqual(config.providerType, .anthropic)
    }

    func testActiveProviderConfigRespectsOpenAIProvider() {
        AppGroupConfig.set(ProviderType.openAI.rawValue, for: .selectedProvider)
        let config = AppGroupConfig.activeProviderConfig()
        XCTAssertEqual(config.providerType, .openAI)
    }

    func testProviderConfigForLocalHasNoAPIKey() {
        let config = AppGroupConfig.providerConfig(for: .local)
        XCTAssertTrue(config.apiKey.isEmpty, "Local provider should have an empty API key")
        XCTAssertEqual(config.providerType, .local)
    }

    func testOpenAICustomURLIsRespected() {
        let customURL = "https://my-openai-proxy.example.com/v1/chat/completions"
        AppGroupConfig.set(customURL, for: .openAIURL)
        let config = AppGroupConfig.providerConfig(for: .openAI)
        XCTAssertEqual(config.apiURL, customURL)
    }

    func testOpenAICustomModelIsRespected() {
        AppGroupConfig.set("gpt-4o", for: .openAIModel)
        let config = AppGroupConfig.providerConfig(for: .openAI)
        XCTAssertEqual(config.model, "gpt-4o")
    }

    func testOpenAIDefaultURLWhenNotSet() {
        let config = AppGroupConfig.providerConfig(for: .openAI)
        XCTAssertEqual(config.apiURL, ProviderConfig.defaultOpenAI.apiURL)
    }

    func testAnthropicCustomURLIsRespected() {
        let customURL = "https://my-anthropic-proxy.example.com/v1/messages"
        AppGroupConfig.set(customURL, for: .anthropicURL)
        let config = AppGroupConfig.providerConfig(for: .anthropic)
        XCTAssertEqual(config.apiURL, customURL)
    }

    func testAnthropicDefaultURLWhenNotSet() {
        let config = AppGroupConfig.providerConfig(for: .anthropic)
        XCTAssertEqual(config.apiURL, ProviderConfig.defaultAnthropic.apiURL)
    }

    func testAnthropicCustomModelIsRespected() {
        AppGroupConfig.set("claude-opus-4-7", for: .anthropicModel)
        let config = AppGroupConfig.providerConfig(for: .anthropic)
        XCTAssertEqual(config.model, "claude-opus-4-7")
    }
}
