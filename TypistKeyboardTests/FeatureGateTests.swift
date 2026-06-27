import XCTest
@testable import TypistKeyboard

final class FeatureGateTests: XCTestCase {

    override func setUp() {
        super.setUp()
        FeatureGate.shared.setPassthrough(true)
    }

    override func tearDown() {
        FeatureGate.shared.setPassthrough(true)
        super.tearDown()
    }

    // MARK: - Passthrough mode

    func testPassthroughEnablesAllFeatures() {
        FeatureGate.shared.setPassthrough(true)
        for feature in PremiumFeature.allCases {
            XCTAssertTrue(
                FeatureGate.shared.isEnabled(feature),
                "\(feature.rawValue) should be enabled in passthrough mode"
            )
        }
    }

    func testNonPassthroughDisablesAllFeatures() {
        FeatureGate.shared.setPassthrough(false)
        for feature in PremiumFeature.allCases {
            XCTAssertFalse(
                FeatureGate.shared.isEnabled(feature),
                "\(feature.rawValue) should be disabled when passthrough is off and no entitlements exist"
            )
        }
    }

    // MARK: - Feature constants

    func testAdvancedGrammarFeatureKey() {
        XCTAssertEqual(PremiumFeature.advancedGrammar.rawValue, "ADVANCED_GRAMMAR")
    }

    func testToneSuggestionsFeatureKey() {
        XCTAssertEqual(PremiumFeature.toneSuggestions.rawValue, "TONE_SUGGESTIONS")
    }

    func testMultiLanguageFeatureKey() {
        XCTAssertEqual(PremiumFeature.multiLanguage.rawValue, "MULTI_LANGUAGE")
    }

    func testAllCasesCount() {
        XCTAssertEqual(PremiumFeature.allCases.count, 3)
    }
}
