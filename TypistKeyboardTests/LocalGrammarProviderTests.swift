import XCTest
@testable import TypistKeyboard

final class LocalGrammarProviderTests: XCTestCase {
    private let provider = LocalGrammarProvider()

    func testCorrectReturnsOriginalText() async throws {
        let input = "This is a test sentence."
        let result = try await provider.correct(GrammarRequest(text: input))
        XCTAssertEqual(result.correctedText, input, "Local provider should return input unchanged")
        XCTAssertNotNil(result.explanation, "Local provider should include a 'coming soon' explanation")
    }

    func testValidateDoesNotThrow() async {
        do {
            try await provider.validate()
        } catch {
            XCTFail("Local provider validate should not throw: \(error)")
        }
    }

    func testProviderIdAndDisplayName() {
        XCTAssertEqual(provider.providerId, "local")
        XCTAssertFalse(provider.displayName.isEmpty)
    }
}
