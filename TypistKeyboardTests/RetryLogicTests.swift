import XCTest
@testable import TypistKeyboard

// MARK: - Helpers

private let anthropicSuccessBody = """
{"content": [{"type": "text", "text": "Fixed."}]}
"""
private let openAISuccessBody = """
{"choices": [{"message": {"content": "Fixed."}}]}
"""

private func anthropicOKResponse() -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: "https://api.anthropic.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
}
private func anthropicResponse(_ status: Int, headers: [String: String]? = nil) -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: "https://api.anthropic.com")!, statusCode: status, httpVersion: nil, headerFields: headers)!
}
private func openAIOKResponse() -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: "https://api.openai.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
}
private func openAIResponse(_ status: Int, headers: [String: String]? = nil) -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: "https://api.openai.com")!, statusCode: status, httpVersion: nil, headerFields: headers)!
}

// MARK: - Anthropic retry tests

final class AnthropicProviderRetryTests: XCTestCase {

    private var session: URLSession!
    private var sleepDelays: [TimeInterval]!

    override func setUp() {
        super.setUp()
        session = .makeMockSession()
        sleepDelays = []
    }

    private func makeSleeper() -> HTTPSleeper {
        return { [unowned self] delay in self.sleepDelays.append(delay) }
    }

    private func makeProvider(apiKey: String = "test-key") -> AnthropicProvider {
        AnthropicProvider(
            config: ProviderConfig(
                providerType: .anthropic,
                apiURL: "https://api.anthropic.com/v1/messages",
                model: "claude-haiku-4-5-20251001",
                apiKey: apiKey
            ),
            session: session,
            sleeper: makeSleeper()
        )
    }

    // MARK: 429 rate-limit retry

    func test429ExhaustsRetriesAndThrowsRateLimited() async {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            return (anthropicResponse(429), Data())
        }

        do {
            _ = try await makeProvider().correct(GrammarRequest(text: "test"))
            XCTFail("Expected rateLimited")
        } catch GrammarProviderError.rateLimited {
            XCTAssertEqual(callCount, 3, "Should make 1 initial + 2 retry calls")
            XCTAssertEqual(sleepDelays, [1.0, 2.0], "Exponential backoff: 1s then 2s")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test429UsesRetryAfterHeader() async {
        MockURLProtocol.requestHandler = { _ in
            return (anthropicResponse(429, headers: ["Retry-After": "5"]), Data())
        }

        do {
            _ = try await makeProvider().correct(GrammarRequest(text: "test"))
            XCTFail("Expected rateLimited")
        } catch GrammarProviderError.rateLimited {
            XCTAssertEqual(sleepDelays, [5.0, 5.0], "Should use Retry-After value for each delay")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test429RecoveryOnSecondAttempt() async throws {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            if callCount == 1 {
                return (anthropicResponse(429), Data())
            }
            return (anthropicOKResponse(), anthropicSuccessBody.data(using: .utf8)!)
        }

        let result = try await makeProvider().correct(GrammarRequest(text: "test"))
        XCTAssertEqual(result.correctedText, "Fixed.")
        XCTAssertEqual(callCount, 2)
        XCTAssertEqual(sleepDelays, [1.0])
    }

    func test429RecoveryOnThirdAttempt() async throws {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            if callCount <= 2 {
                return (anthropicResponse(429), Data())
            }
            return (anthropicOKResponse(), anthropicSuccessBody.data(using: .utf8)!)
        }

        let result = try await makeProvider().correct(GrammarRequest(text: "test"))
        XCTAssertEqual(result.correctedText, "Fixed.")
        XCTAssertEqual(callCount, 3)
        XCTAssertEqual(sleepDelays, [1.0, 2.0])
    }

    // MARK: 408 request-timeout retry

    func test408RetriesOnceAndThrowsOnSecond408() async {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            return (anthropicResponse(408), Data())
        }

        do {
            _ = try await makeProvider().correct(GrammarRequest(text: "test"))
            XCTFail("Expected serverError(408, ...)")
        } catch GrammarProviderError.serverError(let code, _) {
            XCTAssertEqual(code, 408)
            XCTAssertEqual(callCount, 2, "Should make 1 initial + 1 retry call")
            XCTAssertEqual(sleepDelays, [1.0], "Should sleep 1s before retry")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test408RecoveryOnRetry() async throws {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            if callCount == 1 {
                return (anthropicResponse(408), Data())
            }
            return (anthropicOKResponse(), anthropicSuccessBody.data(using: .utf8)!)
        }

        let result = try await makeProvider().correct(GrammarRequest(text: "test"))
        XCTAssertEqual(result.correctedText, "Fixed.")
        XCTAssertEqual(callCount, 2)
        XCTAssertEqual(sleepDelays, [1.0])
    }

    // MARK: Non-retried errors

    func testURLErrorTimedOutDoesNotRetry() async {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            throw URLError(.timedOut)
        }

        do {
            _ = try await makeProvider().correct(GrammarRequest(text: "test"))
            XCTFail("Expected serverError")
        } catch GrammarProviderError.serverError(let code, _) {
            XCTAssertEqual(code, 0)
            XCTAssertEqual(callCount, 1, "URLError.timedOut should NOT trigger retry")
            XCTAssertTrue(sleepDelays.isEmpty, "No sleep should occur for URLError")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testNetworkUnavailableDoesNotRetry() async {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await makeProvider().correct(GrammarRequest(text: "test"))
            XCTFail("Expected networkUnavailable")
        } catch GrammarProviderError.networkUnavailable {
            XCTAssertEqual(callCount, 1, "Network errors should not trigger retry")
            XCTAssertTrue(sleepDelays.isEmpty)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test401DoesNotRetry() async {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            return (anthropicResponse(401), Data())
        }

        do {
            _ = try await makeProvider().correct(GrammarRequest(text: "test"))
            XCTFail("Expected unauthorized")
        } catch GrammarProviderError.unauthorized {
            XCTAssertEqual(callCount, 1, "Auth errors should not retry")
            XCTAssertTrue(sleepDelays.isEmpty)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: noApiConfigured

    func testEmptyKeyThrowsNoApiConfigured() async {
        MockURLProtocol.requestHandler = { _ in XCTFail("Should not hit network"); return (anthropicOKResponse(), Data()) }
        do {
            _ = try await makeProvider(apiKey: "").correct(GrammarRequest(text: "test"))
            XCTFail("Expected noApiConfigured")
        } catch GrammarProviderError.noApiConfigured {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - OpenAI retry tests

final class OpenAIProviderRetryTests: XCTestCase {

    private var session: URLSession!
    private var sleepDelays: [TimeInterval]!

    override func setUp() {
        super.setUp()
        session = .makeMockSession()
        sleepDelays = []
    }

    private func makeSleeper() -> HTTPSleeper {
        return { [unowned self] delay in self.sleepDelays.append(delay) }
    }

    private func makeProvider(apiKey: String = "test-key") -> OpenAIProvider {
        OpenAIProvider(
            config: ProviderConfig(
                providerType: .openAI,
                apiURL: "https://api.openai.com/v1/chat/completions",
                model: "gpt-4o-mini",
                apiKey: apiKey
            ),
            session: session,
            sleeper: makeSleeper()
        )
    }

    // MARK: 429 rate-limit retry

    func test429ExhaustsRetriesAndThrowsRateLimited() async {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            return (openAIResponse(429), Data())
        }

        do {
            _ = try await makeProvider().correct(GrammarRequest(text: "test"))
            XCTFail("Expected rateLimited")
        } catch GrammarProviderError.rateLimited {
            XCTAssertEqual(callCount, 3, "Should make 1 initial + 2 retry calls")
            XCTAssertEqual(sleepDelays, [1.0, 2.0], "Exponential backoff: 1s then 2s")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test429UsesRetryAfterHeader() async {
        MockURLProtocol.requestHandler = { _ in
            return (openAIResponse(429, headers: ["Retry-After": "3"]), Data())
        }

        do {
            _ = try await makeProvider().correct(GrammarRequest(text: "test"))
            XCTFail("Expected rateLimited")
        } catch GrammarProviderError.rateLimited {
            XCTAssertEqual(sleepDelays, [3.0, 3.0])
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test429RecoveryOnSecondAttempt() async throws {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            if callCount == 1 {
                return (openAIResponse(429), Data())
            }
            return (openAIOKResponse(), openAISuccessBody.data(using: .utf8)!)
        }

        let result = try await makeProvider().correct(GrammarRequest(text: "test"))
        XCTAssertEqual(result.correctedText, "Fixed.")
        XCTAssertEqual(callCount, 2)
        XCTAssertEqual(sleepDelays, [1.0])
    }

    // MARK: 408 request-timeout retry

    func test408RetriesOnceAndThrowsOnSecond408() async {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            return (openAIResponse(408), Data())
        }

        do {
            _ = try await makeProvider().correct(GrammarRequest(text: "test"))
            XCTFail("Expected serverError(408, ...)")
        } catch GrammarProviderError.serverError(let code, _) {
            XCTAssertEqual(code, 408)
            XCTAssertEqual(callCount, 2, "Should make 1 initial + 1 retry call")
            XCTAssertEqual(sleepDelays, [1.0])
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test408RecoveryOnRetry() async throws {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            if callCount == 1 {
                return (openAIResponse(408), Data())
            }
            return (openAIOKResponse(), openAISuccessBody.data(using: .utf8)!)
        }

        let result = try await makeProvider().correct(GrammarRequest(text: "test"))
        XCTAssertEqual(result.correctedText, "Fixed.")
        XCTAssertEqual(callCount, 2)
        XCTAssertEqual(sleepDelays, [1.0])
    }

    // MARK: Non-retried errors

    func testNetworkLostDoesNotRetry() async {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            throw URLError(.networkConnectionLost)
        }

        do {
            _ = try await makeProvider().correct(GrammarRequest(text: "test"))
            XCTFail("Expected networkUnavailable")
        } catch GrammarProviderError.networkUnavailable {
            XCTAssertEqual(callCount, 1)
            XCTAssertTrue(sleepDelays.isEmpty)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: noApiConfigured

    func testEmptyKeyThrowsNoApiConfigured() async {
        do {
            _ = try await makeProvider(apiKey: "").correct(GrammarRequest(text: "test"))
            XCTFail("Expected noApiConfigured")
        } catch GrammarProviderError.noApiConfigured {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
