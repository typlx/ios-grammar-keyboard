import XCTest
@testable import TypistKeyboard

final class AutoCapHelperTests: XCTestCase {

    // MARK: - Empty / beginning of document

    func testEmptyDocumentShouldCapitalize() {
        XCTAssertTrue(AutoCapHelper.shouldCapitalize(after: ""))
    }

    // MARK: - After period

    func testAfterPeriodAndSpaceShouldCapitalize() {
        XCTAssertTrue(AutoCapHelper.shouldCapitalize(after: "Hello. "))
    }

    func testAfterPeriodWithMultipleSpacesShouldCapitalize() {
        XCTAssertTrue(AutoCapHelper.shouldCapitalize(after: "Hello.  "))
    }

    func testAfterPeriodWithNoSpaceShouldNotCapitalize() {
        // No trailing space yet — the user hasn't pressed space, so we're mid-word
        XCTAssertFalse(AutoCapHelper.shouldCapitalize(after: "Hello."))
    }

    // MARK: - After exclamation mark

    func testAfterExclamationAndSpaceShouldCapitalize() {
        XCTAssertTrue(AutoCapHelper.shouldCapitalize(after: "Wow! "))
    }

    // MARK: - After question mark

    func testAfterQuestionMarkAndSpaceShouldCapitalize() {
        XCTAssertTrue(AutoCapHelper.shouldCapitalize(after: "Really? "))
    }

    // MARK: - Mid-sentence (should NOT capitalize)

    func testMidSentenceShouldNotCapitalize() {
        XCTAssertFalse(AutoCapHelper.shouldCapitalize(after: "Hello "))
    }

    func testAfterCommaAndSpaceShouldNotCapitalize() {
        XCTAssertFalse(AutoCapHelper.shouldCapitalize(after: "Hello, "))
    }

    func testAfterColonAndSpaceShouldNotCapitalize() {
        XCTAssertFalse(AutoCapHelper.shouldCapitalize(after: "Note: "))
    }

    func testSingleWordNoCapitalize() {
        XCTAssertFalse(AutoCapHelper.shouldCapitalize(after: "hello"))
    }

    func testSingleSpaceShouldNotCapitalize() {
        XCTAssertFalse(AutoCapHelper.shouldCapitalize(after: " "))
    }

    // MARK: - After newline

    func testAfterNewlineShouldCapitalize() {
        XCTAssertTrue(AutoCapHelper.shouldCapitalize(after: "Hello.\n"))
    }

    func testAfterNewlineWithSpaceShouldCapitalize() {
        XCTAssertTrue(AutoCapHelper.shouldCapitalize(after: "Hello.\n "))
    }

    // MARK: - Multi-sentence scenarios

    func testSecondSentenceCapitalizesCorrectly() {
        XCTAssertTrue(AutoCapHelper.shouldCapitalize(after: "Hi there. How are you? "))
    }

    func testMidSecondSentenceShouldNotCapitalize() {
        XCTAssertFalse(AutoCapHelper.shouldCapitalize(after: "Hi there. How are you"))
    }

    // MARK: - Abbreviations (should NOT trigger mid-sentence cap)

    func testAbbreviationMidSentenceNoExtraSpace() {
        // "Dr." with cursor right after period, no space yet — no cap
        XCTAssertFalse(AutoCapHelper.shouldCapitalize(after: "Dr."))
    }
}
