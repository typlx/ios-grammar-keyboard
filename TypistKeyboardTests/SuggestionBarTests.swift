import XCTest
@testable import TypistKeyboard

final class SuggestionBarTests: XCTestCase {

    private var bar: SuggestionBar!

    override func setUp() {
        super.setUp()
        bar = SuggestionBar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() {
        UIView.setAnimationsEnabled(true)
        bar = nil
        super.tearDown()
    }

    // MARK: - Mirror helper

    private func buttons() -> [UIButton] {
        Mirror(reflecting: bar!).children
            .first(where: { $0.label == "buttons" })?.value as? [UIButton] ?? []
    }

    // MARK: - update(suggestions:) — button state

    func testUpdateWithThreeSuggestionsEnablesAllButtons() {
        bar.update(suggestions: ["the", "they", "then"])
        let btns = buttons()
        XCTAssertFalse(btns.isEmpty, "SuggestionBar must contain internal buttons")
        for (i, btn) in btns.enumerated() {
            XCTAssertTrue(btn.isEnabled,
                          "Button \(i) should be enabled when suggestion is provided")
        }
    }

    func testUpdateWithEmptyArrayDisablesAllButtons() {
        bar.update(suggestions: ["the", "they", "then"])
        bar.update(suggestions: [])
        for (i, btn) in buttons().enumerated() {
            XCTAssertFalse(btn.isEnabled,
                           "Button \(i) should be disabled after clearing suggestions")
        }
    }

    func testUpdateWithOneSuggestionEnablesOnlyFirstButton() {
        bar.update(suggestions: ["the"])
        let btns = buttons()
        XCTAssertTrue(btns[0].isEnabled,  "First button must be enabled with one suggestion")
        XCTAssertFalse(btns[1].isEnabled, "Second button must be disabled")
        XCTAssertFalse(btns[2].isEnabled, "Third button must be disabled")
    }

    func testUpdateWithTwoSuggestionsEnablesFirstTwoOnly() {
        bar.update(suggestions: ["the", "they"])
        let btns = buttons()
        XCTAssertTrue(btns[0].isEnabled,  "First button must be enabled")
        XCTAssertTrue(btns[1].isEnabled,  "Second button must be enabled")
        XCTAssertFalse(btns[2].isEnabled, "Third button must be disabled with only two suggestions")
    }

    // MARK: - update(suggestions:) — button titles

    func testButtonTitlesMatchSuggestions() {
        let words = ["work", "world", "would"]
        bar.update(suggestions: words)
        let btns = buttons()
        for (i, word) in words.enumerated() {
            XCTAssertEqual(btns[i].title(for: .normal), word,
                           "Button \(i) title must match suggestion '\(word)'")
        }
    }

    func testClearingSuggestionsClearsButtonTitles() {
        bar.update(suggestions: ["hello", "help", "held"])
        bar.update(suggestions: [])
        for (i, btn) in buttons().enumerated() {
            XCTAssertNil(btn.title(for: .normal),
                         "Button \(i) title must be nil after clearing suggestions")
        }
    }

    func testUpdateWithFewerSuggestionsClearsExtraButtonTitles() {
        bar.update(suggestions: ["hello", "help", "held"])
        bar.update(suggestions: ["hi"])
        let btns = buttons()
        XCTAssertEqual(btns[0].title(for: .normal), "hi",
                       "First button must show the new suggestion")
        XCTAssertNil(btns[1].title(for: .normal),
                     "Second button title must be cleared when fewer suggestions are provided")
        XCTAssertNil(btns[2].title(for: .normal),
                     "Third button title must be cleared when fewer suggestions are provided")
    }

    // MARK: - Delegate interaction

    func testDelegateIsNotifiedWhenEnabledButtonIsTapped() {
        let delegate = MockSuggestionBarDelegate()
        bar.delegate = delegate
        bar.update(suggestions: ["work", "word", "world"])

        let btns = buttons()
        btns[1].sendActions(for: .touchUpInside)

        XCTAssertEqual(delegate.lastSelectedWord, "word",
                       "Delegate must receive the word corresponding to the tapped button index")
    }

    func testDelegateIsNotCalledWhenDisabledButtonIsTapped() {
        let delegate = MockSuggestionBarDelegate()
        bar.delegate = delegate
        bar.update(suggestions: ["work"])

        // Button at index 1 is disabled (no suggestion assigned).
        let btns = buttons()
        btns[1].sendActions(for: .touchUpInside)

        XCTAssertNil(delegate.lastSelectedWord,
                     "Tapping a disabled/empty button must not call the delegate")
    }

    func testDelegateIsWeaklyHeld() {
        var delegate: MockSuggestionBarDelegate? = MockSuggestionBarDelegate()
        bar.delegate = delegate
        XCTAssertNotNil(bar.delegate)
        delegate = nil
        XCTAssertNil(bar.delegate, "SuggestionBar.delegate must be weakly held")
    }

    // MARK: - Accessibility identifiers

    func testButtonsHaveAccessibilityIdentifiers() {
        let btns = buttons()
        for (i, btn) in btns.enumerated() {
            XCTAssertEqual(btn.accessibilityIdentifier, "suggestionButton\(i)",
                           "Button \(i) must have accessibilityIdentifier 'suggestionButton\(i)'")
        }
    }
}

// MARK: - Helpers

private final class MockSuggestionBarDelegate: SuggestionBarDelegate {
    var lastSelectedWord: String?

    func suggestionBar(_ bar: SuggestionBar, didSelect word: String) {
        lastSelectedWord = word
    }
}
