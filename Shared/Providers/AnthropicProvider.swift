import Foundation

public final class AnthropicProvider: GrammarProvider {
    public let providerId = "anthropic"
    public let displayName = "Anthropic"

    private let config: ProviderConfig
    private let session: URLSession
    private let sleeper: HTTPSleeper

    private static let anthropicVersion = "2023-06-01"

    public init(config: ProviderConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
        self.sleeper = defaultHTTPSleeper
    }

    // Internal init for testing — allows injecting a no-op sleeper to skip real delays.
    init(config: ProviderConfig, session: URLSession, sleeper: @escaping HTTPSleeper) {
        self.config = config
        self.session = session
        self.sleeper = sleeper
    }

    public func validate() async throws {
        guard !config.apiKey.isEmpty else { throw GrammarProviderError.noApiConfigured }
        let request = GrammarRequest(text: "Hello world", context: .general)
        _ = try await correct(request)
    }

    public func correct(_ request: GrammarRequest) async throws -> GrammarResponse {
        guard !config.apiKey.isEmpty else { throw GrammarProviderError.noApiConfigured }

        let url = URL(string: config.apiURL)!
        var urlRequest = URLRequest(url: url, timeoutInterval: 30)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(Self.anthropicVersion, forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": config.model,
            "system": SystemPrompts.prompt(for: request.context, language: request.language),
            "messages": [
                ["role": "user", "content": request.text]
            ],
            "max_tokens": 1024
        ]

        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await performHTTPWithRetry(sleeper: sleeper) {
            try await self.session.data(for: urlRequest)
        }

        let decoded: AnthropicMessagesResponse
        do {
            decoded = try JSONDecoder().decode(AnthropicMessagesResponse.self, from: data)
        } catch {
            throw GrammarProviderError.invalidResponse
        }
        guard let textBlock = decoded.content.first(where: { $0.type == "text" }) else {
            throw GrammarProviderError.invalidResponse
        }
        return GrammarResponse(correctedText: textBlock.text.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

// MARK: - Response Models

private struct AnthropicMessagesResponse: Decodable {
    struct ContentBlock: Decodable {
        let type: String
        let text: String
    }
    let content: [ContentBlock]
}
