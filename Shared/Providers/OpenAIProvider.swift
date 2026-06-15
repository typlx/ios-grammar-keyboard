import Foundation

public final class OpenAIProvider: GrammarProvider {
    public let providerId = "openai"
    public let displayName = "OpenAI"

    private let config: ProviderConfig
    private let session: URLSession

    public init(config: ProviderConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    public func validate() async throws {
        guard !config.apiKey.isEmpty else { throw GrammarProviderError.unauthorized }
        let request = GrammarRequest(text: "Hello world", context: .general)
        _ = try await correct(request)
    }

    public func correct(_ request: GrammarRequest) async throws -> GrammarResponse {
        guard !config.apiKey.isEmpty else { throw GrammarProviderError.unauthorized }

        let url = URL(string: config.apiURL)!
        var urlRequest = URLRequest(url: url, timeoutInterval: 15)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "system", "content": SystemPrompts.prompt(for: request.context)],
                ["role": "user", "content": request.text]
            ],
            "max_tokens": 1024,
            "temperature": 0
        ]

        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost:
                throw GrammarProviderError.networkUnavailable
            case .timedOut:
                throw GrammarProviderError.serverError(0, "Request timed out. Try again.")
            default:
                throw GrammarProviderError.networkUnavailable
            }
        }
        try validate(httpResponse: response, data: data)

        let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw GrammarProviderError.invalidResponse
        }
        return GrammarResponse(correctedText: content.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func validate(httpResponse: URLResponse, data: Data) throws {
        guard let http = httpResponse as? HTTPURLResponse else {
            throw GrammarProviderError.invalidResponse
        }
        switch http.statusCode {
        case 200...299: return
        case 401: throw GrammarProviderError.unauthorized
        case 429: throw GrammarProviderError.rateLimited
        default:
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            throw GrammarProviderError.serverError(http.statusCode, msg)
        }
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
