import XCTest
@testable import TypistKeyboard

final class AnthropicProviderTests: XCTestCase {

    private var session: URLSession!
    private var provider: AnthropicProvider!

    override func setUp() {
        super.setUp()
        session = .makeMockSession()
        provider = AnthropicProvider(
            config: ProviderConfig(
                providerType: .anthropic,
                apiURL: "https://api.anthropic.com/v1/messages",
                model: "claude-haiku-4-5-20251001",
                apiKey: "test-anthropic-key"
            ),
            session: session
        )
    }

    func testCorrectReturnsFixedText() async throws {
        MockURLProtocol.requestHandler = { _ in
            let body = """
            {
              "content": [
                { "type": "text", "text": "Hello, world!" }
              ]
            }
            """
            let response = HTTPURLResponse(
                url: URL(string: "https://api.anthropic.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, body.data(using: .utf8)!)
        }

        let result = try await provider.correct(GrammarRequest(text: "hello world"))
        XCTAssertEqual(result.correctedText, "Hello, world!")
    }

    func testCorrectThrowsUnauthorizedOn401() async {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(url: URL(string: "https://api.anthropic.com")!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        do {
            _ = try await provider.correct(GrammarRequest(text: "test"))
            XCTFail("Expected unauthorized error")
        } catch GrammarProviderError.unauthorized {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRequestIncludesAnthropicVersionHeader() async throws {
        var capturedRequest: URLRequest?

        MockURLProtocol.requestHandler = { req in
            capturedRequest = req
            let body = """{"content": [{"type": "text", "text": "Fixed."}]}"""
            let response = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, body.data(using: .utf8)!)
        }

        _ = try await provider.correct(GrammarRequest(text: "test"))

        XCTAssertNotNil(capturedRequest?.value(forHTTPHeaderField: "anthropic-version"))
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "x-api-key"), "test-anthropic-key")
        XCTAssertNil(capturedRequest?.value(forHTTPHeaderField: "Authorization"),
                     "Anthropic uses x-api-key, not Bearer Authorization")
    }

    func testIgnoresNonTextContentBlocks() async throws {
        MockURLProtocol.requestHandler = { _ in
            let body = """
            {
              "content": [
                { "type": "tool_use", "text": "should be ignored" },
                { "type": "text", "text": "Correct answer." }
              ]
            }
            """
            let response = HTTPURLResponse(url: URL(string: "https://api.anthropic.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, body.data(using: .utf8)!)
        }

        let result = try await provider.correct(GrammarRequest(text: "test"))
        XCTAssertEqual(result.correctedText, "Correct answer.")
    }

    func testEmptyAPIKeyThrowsUnauthorized() async {
        let emptyKeyProvider = AnthropicProvider(
            config: ProviderConfig(providerType: .anthropic, apiURL: "https://api.anthropic.com/v1/messages", model: "claude-haiku-4-5-20251001", apiKey: ""),
            session: session
        )

        do {
            _ = try await emptyKeyProvider.correct(GrammarRequest(text: "test"))
            XCTFail("Expected unauthorized error")
        } catch GrammarProviderError.unauthorized {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
