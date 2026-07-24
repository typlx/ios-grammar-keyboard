import XCTest
@testable import TypistKeyboard

final class AutocorrectDictionaryTests: XCTestCase {

    // MARK: - Known mappings from original 18

    func testOriginalTypoTehReturnsThe() {
        XCTAssertEqual(AutocorrectDictionary.correction(for: "teh"), "the")
    }

    func testOriginalTypoAdnReturnsAnd() {
        XCTAssertEqual(AutocorrectDictionary.correction(for: "adn"), "and")
    }

    func testOriginalTypoFreindReturnsFriend() {
        XCTAssertEqual(AutocorrectDictionary.correction(for: "freind"), "friend")
    }

    func testOriginalTypoDefinatelyReturnsDefinitely() {
        XCTAssertEqual(AutocorrectDictionary.correction(for: "definately"), "definitely")
    }

    // MARK: - Expanded dictionary entries

    func testBecauseTypoReturnsCorrect() {
        XCTAssertEqual(AutocorrectDictionary.correction(for: "becuase"), "because")
    }

    func testShouldTypoReturnsCorrect() {
        XCTAssertEqual(AutocorrectDictionary.correction(for: "shoudl"), "should")
    }

    func testReceiveTypoReturnsCorrect() {
        XCTAssertEqual(AutocorrectDictionary.correction(for: "recieve"), "receive")
    }

    func testSeparateTypoReturnsCorrect() {
        XCTAssertEqual(AutocorrectDictionary.correction(for: "seperate"), "separate")
    }

    func testAccommodateTypoReturnsCorrect() {
        XCTAssertEqual(AutocorrectDictionary.correction(for: "accomodate"), "accommodate")
    }

    func testTomorrowTypoReturnsCorrect() {
        XCTAssertEqual(AutocorrectDictionary.correction(for: "tommorrow"), "tomorrow")
    }

    func testOccurredTypoReturnsCorrect() {
        XCTAssertEqual(AutocorrectDictionary.correction(for: "occured"), "occurred")
    }

    func testEnvironmentTypoReturnsCorrect() {
        XCTAssertEqual(AutocorrectDictionary.correction(for: "enviroment"), "environment")
    }

    // MARK: - Unknown word returns nil

    func testCorrectWordReturnsNil() {
        XCTAssertNil(AutocorrectDictionary.correction(for: "hello"))
    }

    func testEmptyWordReturnsNil() {
        XCTAssertNil(AutocorrectDictionary.correction(for: ""))
    }

    // MARK: - Case preservation: lowercase

    func testLowercaseTypoReturnsCorrectedLowercase() {
        let result = AutocorrectDictionary.correction(for: "teh")
        XCTAssertEqual(result, "the")
    }

    // MARK: - Case preservation: Capitalized

    func testCapitalizedTypoReturnsCorrectedCapitalized() {
        let result = AutocorrectDictionary.correction(for: "Teh")
        XCTAssertEqual(result, "The", "Capitalized input must yield Capitalized output")
    }

    func testCapitalizedBecauseTypo() {
        let result = AutocorrectDictionary.correction(for: "Becuase")
        XCTAssertEqual(result, "Because")
    }

    // MARK: - Case preservation: ALL_CAPS

    func testAllCapsTypoReturnsCorrectedAllCaps() {
        let result = AutocorrectDictionary.correction(for: "TEH")
        XCTAssertEqual(result, "THE", "ALL_CAPS input must yield ALL_CAPS output")
    }

    func testAllCapsBecauseTypo() {
        let result = AutocorrectDictionary.correction(for: "BECUASE")
        XCTAssertEqual(result, "BECAUSE")
    }

    func testAllCapsSeparateTypo() {
        let result = AutocorrectDictionary.correction(for: "SEPERATE")
        XCTAssertEqual(result, "SEPARATE")
    }

    // MARK: - preserveCase helper

    func testPreserveCaseAllCaps() {
        XCTAssertEqual(AutocorrectDictionary.preserveCase(of: "TEH", applyingTo: "the"), "THE")
    }

    func testPreserveCaseCapitalized() {
        XCTAssertEqual(AutocorrectDictionary.preserveCase(of: "Teh", applyingTo: "the"), "The")
    }

    func testPreserveCaseLowercase() {
        XCTAssertEqual(AutocorrectDictionary.preserveCase(of: "teh", applyingTo: "the"), "the")
    }

    func testPreserveCaseSingleCharUpperNotTreatedAsAllCaps() {
        // A single uppercase character should be treated as Capitalized, not ALL_CAPS.
        XCTAssertEqual(AutocorrectDictionary.preserveCase(of: "A", applyingTo: "a"), "A")
    }

    // MARK: - Dictionary size

    func testDictionaryContainsMoreThan100Entries() {
        XCTAssertGreaterThan(AutocorrectDictionary.corrections.count, 100,
                             "Dictionary must have more than 100 entries after expansion")
    }
}
