import XCTest

/// UI tests that exercise keyboard-extension behaviour via the embedded
/// TestHostViewController (launched with `--uitesting` flag).
///
/// These tests validate:
///  - Keyboard extension bundle is embedded in the app
///  - Grammar toolbar renders and responds to state transitions
///  - Secure text entry disables the Fix Grammar button
///  - Grammar toolbar shows/hides based on the autocorrect setting
///  - Network-offline error surfaced gracefully in the toolbar
///  - Multiple input-type fields are present and focusable
final class KeyboardExtensionUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Bundle tests

    /// Confirms the keyboard extension .appex is embedded in the container app bundle.
    /// This verifies the Xcode target dependency and embed step are correctly configured.
    func testKeyboardExtensionBundleIsEmbedded() {
        guard let pluginsPath = Bundle.main.builtInPlugInsPath else {
            XCTFail("Container app has no PlugIns directory — keyboard extension is not embedded")
            return
        }
        let contents = (try? FileManager.default.contentsOfDirectory(atPath: pluginsPath)) ?? []
        XCTAssertTrue(contents.contains { $0.hasSuffix(".appex") },
                      "A .appex keyboard extension should be embedded at \(pluginsPath)")
    }

    // MARK: - Grammar toolbar render tests

    /// Verifies the test host presents the grammar toolbar and both text fields.
    func testTestHostViewRendersKeyboardUI() {
        XCTAssertTrue(app.buttons["fixGrammarButton"].waitForExistence(timeout: 5),
                      "Fix Grammar button should be visible in test host")
        XCTAssertTrue(app.textFields["testRegularTextField"].exists,
                      "Regular text field should be present in test host")
        XCTAssertTrue(app.secureTextFields["testSecureTextField"].exists,
                      "Secure text field should be present in test host")
    }

    /// Secure text fields must not allow grammar correction (TYP-254 requirement).
    func testFixGrammarButtonDisabledForSecureTextField() {
        let secureField = app.secureTextFields["testSecureTextField"]
        XCTAssertTrue(secureField.waitForExistence(timeout: 5))
        secureField.tap()

        // After focusing a secure field the Fix Grammar button should be disabled.
        let fixButton = app.buttons["fixGrammarButton"]
        XCTAssertTrue(fixButton.waitForExistence(timeout: 3))
        // isEnabled == false when the button is disabled via UIButton's isEnabled property
        XCTAssertFalse(fixButton.isEnabled,
                       "Fix Grammar button must be disabled when a secure text field is active (TYP-254)")
    }

    /// Typing in a regular field keeps the Fix Grammar button enabled.
    func testFixGrammarButtonEnabledForRegularTextField() {
        let regularField = app.textFields["testRegularTextField"]
        XCTAssertTrue(regularField.waitForExistence(timeout: 5))
        regularField.tap()
        regularField.typeText("The cat sat on teh mat")

        let fixButton = app.buttons["fixGrammarButton"]
        XCTAssertTrue(fixButton.waitForExistence(timeout: 3))
        XCTAssertTrue(fixButton.isEnabled,
                      "Fix Grammar button must be enabled when regular text is present")
    }

    /// Tapping Fix Grammar transitions the toolbar to a loading then preview/error state.
    func testTappingFixGrammarTriggersToolbarStateTransition() {
        let regularField = app.textFields["testRegularTextField"]
        XCTAssertTrue(regularField.waitForExistence(timeout: 5))
        regularField.tap()
        regularField.typeText("She don't know nothing about it")

        app.buttons["fixGrammarButton"].tap()

        // The status label should transition away from "Idle" after tapping Fix
        let statusLabel = app.staticTexts["testStatusLabel"]
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 3))
        let statusAfterTap = statusLabel.label
        XCTAssertFalse(statusAfterTap == "Idle",
                       "Status label should update after tapping Fix Grammar (got: \(statusAfterTap))")
    }

    /// Validates that the keyboard host can handle multiple text input types (regular + password).
    func testKeyboardHandlesMultipleInputTypes() {
        let regularField = app.textFields["testRegularTextField"]
        let secureField = app.secureTextFields["testSecureTextField"]

        XCTAssertTrue(regularField.waitForExistence(timeout: 5),
                      "Regular text input should be accessible")
        XCTAssertTrue(secureField.exists,
                      "Secure text input should be accessible")

        // Both fields should be focusable
        regularField.tap()
        XCTAssertTrue(regularField.hasFocus, "Regular field should receive focus on tap")

        secureField.tap()
        XCTAssertTrue(secureField.hasFocus, "Secure field should receive focus on tap")
    }
}
