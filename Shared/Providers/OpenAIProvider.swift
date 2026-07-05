import Foundation

public final class OpenAIProvider: GrammarProvider {
    public let providerId = "openai"
    public let displayName = "OpenAI"

    private let config: ProviderConfig
    private let session: URLSession
    private let sleeper: HTTPSleeper

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
        urlRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "system", "content": SystemPrompts.prompt(for: request.context, language: request.language)],
                ["role": "user", "content": request.text]
            ],
            "max_tokens": 1024,
            "temperature": 0
        ]

        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await performHTTPWithRetry(sleeper: sleeper) {
            try await self.session.data(for: urlRequest)
        }

        let decoded: OpenAIChatResponse
        do {
            decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        } catch {
            throw GrammarProviderError.invalidResponse
        }
        guard let content = decoded.choices.first?.message.content else {
            throw GrammarProviderError.invalidResponse
        }
        return GrammarResponse(correctedText: content.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

// MARK: - Response Models

private struct OpenAIChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
