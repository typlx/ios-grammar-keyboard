import XCTest

/// UI tests for the Settings screen: navigation, toggle interactions, and persistence.
final class SettingsUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    private func openSettings() {
        app.buttons["openSettingsButton"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5),
                      "Settings navigation bar should appear")
    }

    private func scrollToGrammarSwitch() -> XCUIElement {
        let grammarSwitch = app.switches["grammarCorrectionSwitch"]
        var attempts = 0
        while !grammarSwitch.exists && attempts < 5 {
            app.tables.firstMatch.swipeUp(velocity: .slow)
            attempts += 1
        }
        return grammarSwitch
    }

    // MARK: - Navigation tests

    func testNavigateToSettingsAndBack() {
        openSettings()
        app.navigationBars["Settings"].buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["mainTitleLabel"].waitForExistence(timeout: 5),
                      "Should return to main screen after tapping back")
    }

    func testSettingsTitleIsVisible() {
        openSettings()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }

    // MARK: - Settings content tests

    func testSettingsContainsProviderSection() {
        openSettings()
        XCTAssertTrue(app.staticTexts["Provider"].waitForExistence(timeout: 5),
                      "Provider section header should be visible in settings")
    }

    func testSettingsContainsKeyboardBehaviorSection() {
        openSettings()
        let behaviorHeader = app.staticTexts["Keyboard Behavior"]
        var attempts = 0
        while !behaviorHeader.exists && attempts < 5 {
            app.tables.firstMatch.swipeUp(velocity: .slow)
            attempts += 1
        }
        XCTAssertTrue(behaviorHeader.exists,
                      "Keyboard Behavior section header should be present in settings")
    }

    // MARK: - Toggle tests

    func testGrammarCorrectionToggleChangesState() {
        openSettings()
        let grammarSwitch = scrollToGrammarSwitch()
        XCTAssertTrue(grammarSwitch.waitForExistence(timeout: 5),
                      "Grammar Correction switch should exist in settings")

        let initialValue = grammarSwitch.value as? String
        grammarSwitch.tap()
        let newValue = grammarSwitch.value as? String
        XCTAssertNotEqual(initialValue, newValue,
                          "Grammar Correction switch value should change after tap")
    }

    func testSettingsSaveNavigatesBackToMain() {
        openSettings()
        app.navigationBars["Settings"].buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["mainTitleLabel"].waitForExistence(timeout: 5),
                      "Tapping Save should return to main screen")
    }

    func testGrammarToggleStatePersistsAfterSave() {
        // Disable grammar correction
        openSettings()
        let grammarSwitch = scrollToGrammarSwitch()
        XCTAssertTrue(grammarSwitch.waitForExistence(timeout: 5))

        if grammarSwitch.value as? String == "1" {
            grammarSwitch.tap()
        }
        XCTAssertEqual(grammarSwitch.value as? String, "0")
        app.navigationBars["Settings"].buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["mainTitleLabel"].waitForExistence(timeout: 5))

        // Re-enter settings and confirm the toggle is still off
        openSettings()
        let persistedSwitch = scrollToGrammarSwitch()
        XCTAssertTrue(persistedSwitch.waitForExistence(timeout: 5))
        XCTAssertEqual(persistedSwitch.value as? String, "0",
                       "Grammar correction setting should persist after save and reopen")

        // Restore to enabled so other test runs start clean
        persistedSwitch.tap()
        app.navigationBars["Settings"].buttons["Save"].tap()
    }

    func testHapticFeedbackToggleChangesState() {
        openSettings()
        let hapticSwitch = app.switches["hapticFeedbackSwitch"]
        var attempts = 0
        while !hapticSwitch.exists && attempts < 5 {
            app.tables.firstMatch.swipeUp(velocity: .slow)
            attempts += 1
        }
        XCTAssertTrue(hapticSwitch.waitForExistence(timeout: 5),
                      "Haptic Feedback switch should exist in settings")
        let initial = hapticSwitch.value as? String
        hapticSwitch.tap()
        XCTAssertNotEqual(initial, hapticSwitch.value as? String,
                          "Haptic Feedback switch value should change after tap")
        // Restore
        hapticSwitch.tap()
        app.navigationBars["Settings"].buttons["Save"].tap()
    }

    func testSettingsContainsSecureTextFieldsForAPIKeys() {
        openSettings()
        XCTAssertTrue(app.secureTextFields.count > 0,
                      "Settings should contain secure text fields for API keys")
    }
}
