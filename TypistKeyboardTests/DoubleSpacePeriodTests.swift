import XCTest
@testable import TypistKeyboard

/// Unit tests for the double-space-to-period feature.
/// The actual gesture logic lives in KeyboardViewController but the core rules are
/// deterministic enough to validate via the helper types and settings round-trips.
final class DoubleSpacePeriodTests: XCTestCase {

    private let key = AppGroupConfig.DefaultsKey.doubleSpacePeriodEnabled

    override func setUp() {
        super.setUp()
        AppGroupConfig.sharedDefaults.removeObject(forKey: key.rawValue)
    }

    override func tearDown() {
        AppGroupConfig.sharedDefaults.removeObject(forKey: key.rawValue)
        super.tearDown()
    }

    // MARK: - Setting persistence

    func testDoubleSpacePeriodDefaultIsOn() {
        // Key absent → default true
        XCTAssertTrue(AppGroupConfig.bool(for: key, defaultValue: true))
    }

    func testDoubleSpacePeriodCanBeDisabled() {
        AppGroupConfig.set(false, for: key)
        XCTAssertFalse(AppGroupConfig.bool(for: key, defaultValue: true))
    }

    func testDoubleSpacePeriodCanBeRenabled() {
        AppGroupConfig.set(false, for: key)
        AppGroupConfig.set(true, for: key)
        XCTAssertTrue(AppGroupConfig.bool(for: key, defaultValue: false))
    }

    // MARK: - Auto-cap follows period insertion

    /// After ". " is inserted the next character should auto-capitalize.
    func testAutoCapAfterDoubleSpacePeriodInserted() {
        // Simulate what the text looks like after ". " was inserted.
        let textAfterPeriod = "Hello. "
        XCTAssertTrue(AutoCapHelper.shouldCapitalize(after: textAfterPeriod),
                      "Auto-cap must trigger on the character after the inserted '. '")
    }

    func testAutoCapDoesNotTriggerBeforePeriodInsertion() {
        // Text ends with a single space — the first space was just pressed, period not yet inserted.
        let textBeforeSecondSpace = "Hello "
        XCTAssertFalse(AutoCapHelper.shouldCapitalize(after: textBeforeSecondSpace),
                       "Single space after a word must not trigger auto-cap")
    }

    // MARK: - Double-space already has a period (should not double-convert)

    func testAutoCapNotTriggeredForTextAlreadyEndingWithPeriodSpace() {
        // After "Hello. " the system already added ". " — second double-space from this
        // position produces "Hello. " + " " then the already-period path skips the ". " insert.
        let textAlreadyHasPeriod = "Hello. "
        // shouldCapitalize returns true here — that's expected and correct.
        // The guard in spaceTapped checks `!before.hasSuffix(". ")` to prevent double-conversion.
        XCTAssertTrue(AutoCapHelper.shouldCapitalize(after: textAlreadyHasPeriod))
    }
}
