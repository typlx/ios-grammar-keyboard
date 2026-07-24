import XCTest
@testable import TypistKeyboard

final class EmojiSuggestionHelperTests: XCTestCase {

    // MARK: - Exact match

    func testExactMatchReturnsEmoji() {
        let result = EmojiSuggestionHelper.emojis(for: "happy")
        XCTAssertFalse(result.isEmpty, "Exact match for 'happy' should return emoji")
    }

    func testFireReturnsFlameEmoji() {
        let result = EmojiSuggestionHelper.emojis(for: "fire")
        XCTAssertTrue(result.contains("🔥"), "'fire' should include 🔥")
    }

    func testLoveReturnsHeartEmoji() {
        let result = EmojiSuggestionHelper.emojis(for: "love")
        XCTAssertTrue(result.contains("❤️"), "'love' should include ❤️")
    }

    func testPartyReturnsBalloonEmoji() {
        let result = EmojiSuggestionHelper.emojis(for: "party")
        XCTAssertTrue(result.contains("🎉"), "'party' should include 🎉")
    }

    // MARK: - Case insensitivity

    func testUppercaseMatchesSameAsLowercase() {
        let lower = EmojiSuggestionHelper.emojis(for: "happy")
        let upper = EmojiSuggestionHelper.emojis(for: "HAPPY")
        XCTAssertEqual(lower, upper, "Matching should be case insensitive")
    }

    func testMixedCaseMatchesSameAsLowercase() {
        let lower = EmojiSuggestionHelper.emojis(for: "pizza")
        let mixed = EmojiSuggestionHelper.emojis(for: "Pizza")
        XCTAssertEqual(lower, mixed, "Mixed case should produce the same result as lowercase")
    }

    func testAllCapsKnownWordReturnsEmoji() {
        let result = EmojiSuggestionHelper.emojis(for: "FIRE")
        XCTAssertFalse(result.isEmpty, "ALL-CAPS known word should return emoji")
    }

    // MARK: - Punctuation stripping

    func testTrailingExclamationIsIgnored() {
        let withPunct = EmojiSuggestionHelper.emojis(for: "happy!")
        let withoutPunct = EmojiSuggestionHelper.emojis(for: "happy")
        XCTAssertEqual(withPunct, withoutPunct,
                       "Trailing '!' should be stripped before lookup")
    }

    func testTrailingPeriodIsIgnored() {
        let withPunct = EmojiSuggestionHelper.emojis(for: "fire.")
        let withoutPunct = EmojiSuggestionHelper.emojis(for: "fire")
        XCTAssertEqual(withPunct, withoutPunct,
                       "Trailing '.' should be stripped before lookup")
    }

    func testTrailingCommaIsIgnored() {
        let withPunct = EmojiSuggestionHelper.emojis(for: "love,")
        let withoutPunct = EmojiSuggestionHelper.emojis(for: "love")
        XCTAssertEqual(withPunct, withoutPunct,
                       "Trailing ',' should be stripped before lookup")
    }

    func testTrailingQuestionMarkIsIgnored() {
        let withPunct = EmojiSuggestionHelper.emojis(for: "happy?")
        let withoutPunct = EmojiSuggestionHelper.emojis(for: "happy")
        XCTAssertEqual(withPunct, withoutPunct,
                       "Trailing '?' should be stripped before lookup")
    }

    // MARK: - No match

    func testUnknownWordReturnsEmpty() {
        let result = EmojiSuggestionHelper.emojis(for: "xyzzy")
        XCTAssertTrue(result.isEmpty, "Unknown word should return an empty array")
    }

    func testEmptyStringReturnsEmpty() {
        let result = EmojiSuggestionHelper.emojis(for: "")
        XCTAssertTrue(result.isEmpty, "Empty string should return an empty array")
    }

    func testPunctuationOnlyReturnsEmpty() {
        let result = EmojiSuggestionHelper.emojis(for: "!!!")
        XCTAssertTrue(result.isEmpty,
                      "String containing only punctuation should return an empty array")
    }

    func testNumberStringReturnsEmpty() {
        let result = EmojiSuggestionHelper.emojis(for: "123")
        XCTAssertTrue(result.isEmpty, "Numeric string should return an empty array")
    }

    // MARK: - Max count

    func testResultIsAtMostThreeEmoji() {
        let words = ["happy", "love", "fire", "pizza", "party", "travel", "music"]
        for word in words {
            let result = EmojiSuggestionHelper.emojis(for: word)
            XCTAssertLessThanOrEqual(result.count, 3,
                "'\(word)' should return at most 3 emoji, got \(result.count)")
        }
    }

    // MARK: - Stem non-matching (exact-match-only semantics)

    func testDerivedFormDoesNotMatchStem() {
        // "happily" is not in the map; only exact "happy" matches
        let result = EmojiSuggestionHelper.emojis(for: "happily")
        XCTAssertTrue(result.isEmpty,
                      "'happily' should not match the stem 'happy' without stemming support")
    }

    func testPluralFormDoesNotMatchSingular() {
        // Only "fire" is in the map, not "fires"
        let singular = EmojiSuggestionHelper.emojis(for: "fire")
        let plural = EmojiSuggestionHelper.emojis(for: "fires")
        XCTAssertFalse(singular.isEmpty, "'fire' should have emoji results")
        XCTAssertTrue(plural.isEmpty,
                      "'fires' should not match 'fire' without stemming support")
    }

    func testProgressiveFormDoesNotMatch() {
        let result = EmojiSuggestionHelper.emojis(for: "running")
        // "running" happens to be in the map; "loving" is not
        let absent = EmojiSuggestionHelper.emojis(for: "loving")
        XCTAssertTrue(absent.isEmpty,
                      "'loving' should not match 'love' without stemming support")
    }
}
