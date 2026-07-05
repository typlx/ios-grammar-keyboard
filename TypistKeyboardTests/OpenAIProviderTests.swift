import XCTest
@testable import TypistKeyboard

final class OpenAIProviderTests: XCTestCase {

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

    func testCorrectReturnsFixedText() async throws {
        MockURLProtocol.requestHandler = { _ in
            let body = """
            {
              "choices": [
                { "message": { "content": "Hello, world!" } }
              ]
            }
            """
            let response = HTTPURLResponse(
                url: URL(string: "https://api.openai.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, body.data(using: .utf8)!)
        }

        let result = try await provider.correct(GrammarRequest(text: "hello world", context: .general))
        XCTAssertEqual(result.correctedText, "Hello, world!")
    }

    func testCorrectThrowsUnauthorizedOn401() async {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.openai.com")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
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

    func testCorrectThrowsRateLimitedOn429() async {
        // Use no-op sleeper to avoid real delays during retry attempts
        let fastProvider = OpenAIProvider(
            config: ProviderConfig(
                providerType: .openAI,
                apiURL: "https://api.openai.com/v1/chat/completions",
                model: "gpt-4o-mini",
                apiKey: "test-key"
            ),
            session: session,
            sleeper: { _ in }
        )
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
            _ = try await fastProvider.correct(GrammarRequest(text: "test"))
            XCTFail("Expected rate limited error")
        } catch GrammarProviderError.rateLimited {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCorrectThrowsWhenEmptyAPIKey() async {
        let emptyKeyProvider = OpenAIProvider(
            config: ProviderConfig(providerType: .openAI, apiURL: "https://api.openai.com/v1/chat/completions", model: "gpt-4o-mini", apiKey: ""),
            session: session
        )

        do {
            _ = try await emptyKeyProvider.correct(GrammarRequest(text: "test"))
            XCTFail("Expected noApiConfigured error")
        } catch GrammarProviderError.noApiConfigured {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRequestIncludesCorrectHeaders() async throws {
        var capturedRequest: URLRequest?

        MockURLProtocol.requestHandler = { req in
            capturedRequest = req
            let body = """{"choices": [{"message": {"content": "Fixed."}}]}"""
            let response = HTTPURLResponse(
                url: req.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, body.data(using: .utf8)!)
        }

        _ = try await provider.correct(GrammarRequest(text: "test"))

        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
    }

    func testContextMappedToCorrectSystemPrompt() async throws {
        var capturedBody: [String: Any]?

        MockURLProtocol.requestHandler = { req in
            if let data = req.httpBody {
                capturedBody = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            }
            let body = """{"choices": [{"message": {"content": "Fixed."}}]}"""
            let response = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, body.data(using: .utf8)!)
        }

        _ = try await provider.correct(GrammarRequest(text: "Dear sir,", context: .email))

        let messages = capturedBody?["messages"] as? [[String: String]]
        let systemMsg = messages?.first(where: { $0["role"] == "system" })?["content"] ?? ""
        XCTAssertTrue(systemMsg.contains("email"), "System prompt should reference email context")
    }
}
