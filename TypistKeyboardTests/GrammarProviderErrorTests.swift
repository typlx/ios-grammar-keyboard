import XCTest
@testable import TypistKeyboard

// Additional error-scenario tests for both network providers.
// Covers: timeout, malformed JSON (→ invalidResponse), server errors, noFullAccess description.

// MARK: - Anthropic additional errors

final class AnthropicProviderErrorTests: XCTestCase {

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
                apiKey: "test-key"
            ),
            session: session
        )
    }

    func testTimeoutThrowsServerError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.timedOut)
        }

        do {
            _ = try await provider.correct(GrammarRequest(text: "test"))
            XCTFail("Expected error")
        } catch GrammarProviderError.serverError(let code, let msg) {
            XCTAssertEqual(code, 0)
            XCTAssertFalse(msg.isEmpty)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testNoConnectionThrowsNetworkUnavailable() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await provider.correct(GrammarRequest(text: "test"))
            XCTFail("Expected networkUnavailable")
        } catch GrammarProviderError.networkUnavailable {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testMalformedJSONResponseThrowsInvalidResponse() async {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.anthropic.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, "not valid json {{{".data(using: .utf8)!)
        }

        do {
            _ = try await provider.correct(GrammarRequest(text: "test"))
            XCTFail("Expected invalidResponse")
        } catch GrammarProviderError.invalidResponse {
            // pass
        } catch {
            XCTFail("Expected GrammarProviderError.invalidResponse but got: \(error)")
        }
    }

    func testMissingTextContentBlockThrowsInvalidResponse() async {
        MockURLProtocol.requestHandler = { _ in
            let body = """{"content": [{"type": "tool_use", "text": "irrelevant"}]}"""
            let response = HTTPURLResponse(
                url: URL(string: "https://api.anthropic.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, body.data(using: .utf8)!)
        }

        do {
            _ = try await provider.correct(GrammarRequest(text: "test"))
            XCTFail("Expected invalidResponse")
        } catch GrammarProviderError.invalidResponse {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRateLimitedOn429() async {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.anthropic.com")!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await provider.correct(GrammarRequest(text: "test"))
            XCTFail("Expected rateLimited")
        } catch GrammarProviderError.rateLimited {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testServerErrorOn500() async {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.anthropic.com")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, "Internal Server Error".data(using: .utf8)!)
        }

        do {
            _ = try await provider.correct(GrammarRequest(text: "test"))
            XCTFail("Expected serverError")
        } catch GrammarProviderError.serverError(let code, _) {
            XCTAssertEqual(code, 500)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testServerErrorOn503() async {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.anthropic.com")!,
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, "Service Unavailable".data(using: .utf8)!)
        }

        do {
            _ = try await provider.correct(GrammarRequest(text: "test"))
            XCTFail("Expected serverError")
        } catch GrammarProviderError.serverError(let code, _) {
            XCTAssertEqual(code, 503)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testServerErrorBodyCaptured() async {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.anthropic.com")!,
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, "overloaded".data(using: .utf8)!)
        }

        do {
            _ = try await provider.correct(GrammarRequest(text: "test"))
            XCTFail("Expected serverError")
        } catch GrammarProviderError.serverError(_, let msg) {
            XCTAssertEqual(msg, "overloaded")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - OpenAI additional errors

final class OpenAIProviderErrorTests: XCTestCase {

    private var session: URLSession!
    private var provider: OpenAIProvider!

    override func setUp() {
        super.setUp()
        session = .makeMockSession()
        provider = OpenAIProvider(
            config: ProviderConfig(
                providerType: .openAI,
                apiURL: "https://api.openai.com/v1/chat/completions",
                model: "gpt-4o-mini",
                apiKey: "test-key"
            ),
            session: session
        )
    }

    func testTimeoutThrowsServerError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.timedOut)
        }

        do {
            _ = try await provider.correct(GrammarRequest(text: "test"))
            XCTFail("Expected error")
        } catch GrammarProviderError.serverError(let code, _) {
            XCTAssertEqual(code, 0)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testNetworkLostThrowsNetworkUnavailable() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.networkConnectionLost)
        }

        do {
            _ = try await provider.correct(GrammarRequest(text: "test"))
            XCTFail("Expected networkUnavailable")
        } catch GrammarProviderError.networkUnavailable {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testMalformedJSONThrowsInvalidResponse() async {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.openai.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, "{ broken json".data(using: .utf8)!)
        }

        do {
            _ = try await provider.correct(GrammarRequest(text: "test"))
            XCTFail("Expected invalidResponse")
        } catch GrammarProviderError.invalidResponse {
            // pass
        } catch {
            XCTFail("Expected GrammarProviderError.invalidResponse but got: \(error)")
        }
    }

    func testEmptyChoicesThrowsInvalidResponse() async {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.openai.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, #"{"choices":[]}"#.data(using: .utf8)!)
        }

        do {
            _ = try await provider.correct(GrammarRequest(text: "test"))
            XCTFail("Expected invalidResponse")
        } catch GrammarProviderError.invalidResponse {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRateLimitedOn429() async {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.openai.com")!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await provider.correct(GrammarRequest(text: "test"))
            XCTFail("Expected rateLimited")
        } catch GrammarProviderError.rateLimited {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testServerErrorOn500() async {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.openai.com")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, "server error body".data(using: .utf8)!)
        }

        do {
            _ = try await provider.correct(GrammarRequest(text: "test"))
            XCTFail("Expected serverError")
        } catch GrammarProviderError.serverError(let code, let msg) {
            XCTAssertEqual(code, 500)
            XCTAssertEqual(msg, "server error body")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - GrammarProviderError descriptions

final class GrammarProviderErrorDescriptionTests: XCTestCase {

    func testNetworkUnavailableDescription() {
        let error = GrammarProviderError.networkUnavailable
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    func testUnauthorizedDescription() {
        let error = GrammarProviderError.unauthorized
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    func testRateLimitedDescription() {
        let error = GrammarProviderError.rateLimited
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    func testServerErrorDescription() {
        let error = GrammarProviderError.serverError(503, "Service unavailable")
        let desc = error.errorDescription ?? ""
        XCTAssertTrue(desc.contains("503"))
    }

    func testInvalidResponseDescription() {
        let error = GrammarProviderError.invalidResponse
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    func testNoFullAccessDescription() {
        let error = GrammarProviderError.noFullAccess
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
        XCTAssertTrue(error.errorDescription?.contains("Full Access") ?? false)
    }
}
