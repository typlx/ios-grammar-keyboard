import XCTest

/// General container-app UI tests: launch, main screen, and navigation smoke tests.
final class TypistKeyboardUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Launch tests

    func testAppLaunchShowsMainScreen() {
        XCTAssertTrue(app.staticTexts["mainTitleLabel"].waitForExistence(timeout: 5),
                      "Main title 'Typist' should be visible after launch")
        XCTAssertTrue(app.buttons["openSettingsButton"].exists,
                      "Open Settings button should be present on main screen")
    }

    func testMainScreenSubtitleIsVisible() {
        let subtitle = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'grammar'")
        ).firstMatch
        XCTAssertTrue(subtitle.waitForExistence(timeout: 5),
                      "Subtitle mentioning grammar should appear on main screen")
    }

    func testNavigationBarExistsOnMainScreen() {
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5),
                      "Navigation bar should be present on main screen")
    }
}
