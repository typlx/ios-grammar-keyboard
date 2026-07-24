import XCTest
@testable import TypistKeyboard

final class KeyAlternativesTests: XCTestCase {

    // MARK: - Mapping structure

    func testAllMappingKeysAreLowercase() {
        for key in KeyAlternatives.qwerty.keys {
            XCTAssertEqual(key, key.lowercased(),
                           "All mapping keys must be lowercase; '\(key)' violates this")
        }
    }

    func testAllMappingValuesAreNonEmpty() {
        for (key, alts) in KeyAlternatives.qwerty {
            XCTAssertFalse(alts.isEmpty,
                           "Key '\(key)' must have at least one alternative")
            for alt in alts {
                XCTAssertFalse(alt.isEmpty,
                               "Alternative in '\(key)' array must not be empty string")
            }
        }
    }

    // MARK: - Vowel accents (acceptance criteria)

    func testVowelsHaveAlternatives() {
        for vowel in ["a", "e", "i", "o", "u"] {
            XCTAssertFalse(KeyAlternatives.alternatives(for: vowel).isEmpty,
                           "'\(vowel)' must have accent alternatives")
        }
    }

    func testEAccents() {
        let alts = KeyAlternatives.alternatives(for: "e")
        XCTAssertTrue(alts.contains("é"), "e → é must be present")
        XCTAssertTrue(alts.contains("è"), "e → è must be present")
        XCTAssertTrue(alts.contains("ê"), "e → ê must be present")
        XCTAssertTrue(alts.contains("ë"), "e → ë must be present")
    }

    func testAAccents() {
        let alts = KeyAlternatives.alternatives(for: "a")
        XCTAssertTrue(alts.contains("à"), "a → à must be present")
        XCTAssertTrue(alts.contains("á"), "a → á must be present")
        XCTAssertTrue(alts.contains("â"), "a → â must be present")
        XCTAssertTrue(alts.contains("ä"), "a → ä must be present")
    }

    func testOAccents() {
        let alts = KeyAlternatives.alternatives(for: "o")
        XCTAssertTrue(alts.contains("ö"), "o → ö must be present")
        XCTAssertTrue(alts.contains("ó"), "o → ó must be present")
        XCTAssertTrue(alts.contains("ô"), "o → ô must be present")
    }

    func testUAccents() {
        let alts = KeyAlternatives.alternatives(for: "u")
        XCTAssertTrue(alts.contains("ü"), "u → ü must be present")
        XCTAssertTrue(alts.contains("ú"), "u → ú must be present")
        XCTAssertTrue(alts.contains("ù"), "u → ù must be present")
    }

    func testIAccents() {
        let alts = KeyAlternatives.alternatives(for: "i")
        XCTAssertTrue(alts.contains("ï"), "i → ï must be present")
        XCTAssertTrue(alts.contains("í"), "i → í must be present")
        XCTAssertTrue(alts.contains("ì"), "i → ì must be present")
    }

    // MARK: - Common consonant alternatives (acceptance criteria)

    func testNHasEnye() {
        let alts = KeyAlternatives.alternatives(for: "n")
        XCTAssertTrue(alts.contains("ñ"), "n → ñ must be present")
    }

    func testSHasEszett() {
        let alts = KeyAlternatives.alternatives(for: "s")
        XCTAssertTrue(alts.contains("ß"), "s → ß must be present")
    }

    func testCHasCedilla() {
        let alts = KeyAlternatives.alternatives(for: "c")
        XCTAssertTrue(alts.contains("ç"), "c → ç must be present")
    }

    // MARK: - Lookup semantics

    func testCaseInsensitiveLookup() {
        XCTAssertEqual(KeyAlternatives.alternatives(for: "e"),
                       KeyAlternatives.alternatives(for: "E"),
                       "Lookup must be case-insensitive")
        XCTAssertEqual(KeyAlternatives.alternatives(for: "A"),
                       KeyAlternatives.alternatives(for: "a"),
                       "Uppercase key must return same alternatives as lowercase")
    }

    func testEmptyStringReturnsEmpty() {
        XCTAssertTrue(KeyAlternatives.alternatives(for: "").isEmpty,
                      "Empty string must return empty alternatives")
    }

    func testUnmappedKeyReturnsEmpty() {
        for key in ["q", "w", "f", "g", "h", "j", "k", "m", "p", "v", "b", "x"] {
            let alts = KeyAlternatives.alternatives(for: key)
            XCTAssertTrue(alts.isEmpty,
                          "'\(key)' has no standard QWERTY accent alternatives; expected empty array")
        }
    }

    func testDeterministicResults() {
        XCTAssertEqual(KeyAlternatives.alternatives(for: "e"),
                       KeyAlternatives.alternatives(for: "e"),
                       "Repeated lookups for the same key must return identical results")
    }

    // MARK: - Long-press release without slide (TYP-539 regression)

    func testLongPressReleaseWithoutSlideYieldsNilSelection() {
        // A fresh popup with no touch activity must report nil — the .ended handler
        // uses this to fall back to inserting the base character instead of
        // swallowing the keypress (fixes TYP-539).
        let popup = AlternativesPopupView(alternatives: ["é", "è", "ê"])
        XCTAssertNil(popup.selectedAlternative,
                     "selectedAlternative must be nil when no alternative has been highlighted")
    }

    func testLongPressSlideHighlightsCorrectAlternative() {
        // Simulate slide: touch lands inside the first cell so the opposite path is
        // covered — an alternative IS selected and should be inserted.
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 200))
        let popup = AlternativesPopupView(alternatives: ["é", "è", "ê"])
        let popupSize = AlternativesPopupView.size(for: 3)
        popup.frame = CGRect(x: 100, y: 100, width: popupSize.width, height: popupSize.height)
        container.addSubview(popup)

        // Touch center of first cell in superview coordinates.
        let touchX = popup.frame.minX + AlternativesPopupView.padding + AlternativesPopupView.cellSize / 2
        let touchY = popup.frame.midY
        popup.updateHighlight(forTouchAt: CGPoint(x: touchX, y: touchY))

        XCTAssertEqual(popup.selectedAlternative, "é",
                       "Sliding over the first cell must select the first alternative")
    }
}
