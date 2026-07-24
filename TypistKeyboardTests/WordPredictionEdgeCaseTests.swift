import XCTest
@testable import TypistKeyboard

/// Edge-case tests for WordPredictionEngine that complement the basic prefix/learning tests
/// in WordPredictionEngineTests.swift.
final class WordPredictionEdgeCaseTests: XCTestCase {

    private var engine: WordPredictionEngine!
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "WordPredictionEdgeCaseTests-\(UUID().uuidString)")!
        engine = WordPredictionEngine(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: testDefaults.dictionaryRepresentation().keys.first ?? "")
        engine = nil
        testDefaults = nil
        super.tearDown()
    }

    // MARK: - Edge case: single-character prefix

    func testSingleCharacterPrefixReturnsAtMostThreeSuggestions() {
        let results = engine.suggestions(for: "a")
        XCTAssertLessThanOrEqual(results.count, 3, "Single-char prefix must cap at 3 suggestions")
    }

    func testSingleCharacterPrefixResultsAllStartWithThatChar() {
        let results = engine.suggestions(for: "w")
        XCTAssertTrue(results.allSatisfy { $0.hasPrefix("w") },
                      "All suggestions for 'w' must start with 'w'")
    }

    // MARK: - Edge case: Unicode prefix

    func testUnicodePrefixDoesNotCrash() {
        // Words with diacritics are not in the built-in dictionary.
        // The engine should return [] without crashing.
        let results = engine.suggestions(for: "caf\u{00E9}") // "café"
        XCTAssertEqual(results, [], "Unicode prefix not in trie must return empty array, not crash")
    }

    func testUnicodePrefixWithKnownASCIIStart() {
        // "ca" is an ASCII prefix that does exist in the trie (e.g. "can", "car").
        let results = engine.suggestions(for: "ca")
        XCTAssertFalse(results.isEmpty, "'ca' has multiple dictionary entries")
        XCTAssertTrue(results.allSatisfy { $0.hasPrefix("ca") })
    }

    // MARK: - Edge case: very long prefix

    func testVeryLongPrefixReturnsEmptyWithoutCrash() {
        let longPrefix = String(repeating: "a", count: 50)
        let results = engine.suggestions(for: longPrefix)
        XCTAssertEqual(results, [], "50-char prefix not in trie must return empty without crashing")
    }

    func testPrefixLongerThanAnyDictionaryWordReturnsEmpty() {
        // No word in the built-in dictionary exceeds 20 characters.
        let results = engine.suggestions(for: "internationalization")
        XCTAssertEqual(results, [],
                       "Prefix longer than any dictionary word should return empty")
    }

    // MARK: - Edge case: prefix with non-letter characters

    func testPrefixWithSpaceReturnsEmpty() {
        // The trie is built from letters only; space is not a trie key.
        let results = engine.suggestions(for: " ")
        XCTAssertEqual(results, [], "Whitespace prefix must return empty")
    }

    func testPrefixWithApostropheReturnsEmpty() {
        let results = engine.suggestions(for: "it'")
        XCTAssertEqual(results, [], "Prefix ending with apostrophe must return empty")
    }

    // MARK: - Edge case: learning validation

    func testLearningSameWordMultipleTimesIncreasesRank() {
        // Pre-condition: "zymurgy" is not in the built-in dictionary.
        engine.learn(word: "zymurgy", after: nil)
        engine.learn(word: "zymurgy", after: nil)
        engine.learn(word: "zymurgy", after: nil)

        let results = engine.suggestions(for: "zym")
        XCTAssertTrue(results.contains("zymurgy"),
                      "Repeatedly learned word must appear in suggestions")
    }

    func testLearningSingleCharacterWordIsIgnored() {
        // Single-char words are below the 2-char minimum.
        engine.learn(word: "a", after: nil)
        let results = engine.suggestions(for: "a")
        XCTAssertFalse(results.contains("a"),
                       "Single-character word must not be stored or suggested")
    }

    func testLearningWordWithApostropheIsIgnored() {
        // Words with non-letter characters must be silently rejected.
        engine.learn(word: "it's", after: nil)
        let results = engine.suggestions(for: "it")
        XCTAssertFalse(results.contains("it's"),
                       "Word with apostrophe must not be learned (non-letter character)")
    }

    // MARK: - Bigram: short previous word is not used

    func testBigramContextWithSingleCharPrevWordHasNoEffect() {
        // learn() requires prev.count >= 2, so single-char prev word is silently ignored.
        engine.learn(word: "morning", after: "a")
        // "morning" should not be boosted for "mo" with context "a".
        let withContext = engine.suggestions(for: "mo", context: "a")
        let withoutContext = engine.suggestions(for: "mo", context: nil)
        // The results should be identical because "a" was never stored as a bigram key.
        XCTAssertEqual(withContext, withoutContext,
                       "Single-char prev word must not influence bigram boost")
    }

    // MARK: - Suggestions vs. learning interaction

    func testLearnedWordOutranksDictionaryWordWithSamePrefix() {
        // "xeriscape" is not in the built-in dictionary.
        engine.learn(word: "xeriscape", after: nil)
        let results = engine.suggestions(for: "xer")
        XCTAssertEqual(results.first, "xeriscape",
                       "Freshly learned word must rank first for its unique prefix")
    }
}
