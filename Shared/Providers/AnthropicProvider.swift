import Foundation

public final class AnthropicProvider: GrammarProvider {
    public let providerId = "anthropic"
    public let displayName = "Anthropic"

    private let config: ProviderConfig
    private let session: URLSession

    // Current Anthropic Messages API version
    private static let anthropicVersion = "2023-06-01"

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
        urlRequest.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(Self.anthropicVersion, forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": config.model,
            "system": SystemPrompts.prompt(for: request.context),
            "messages": [
                ["role": "user", "content": request.text]
            ],
            "max_tokens": 1024
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

        let decoded = try JSONDecoder().decode(AnthropicMessagesResponse.self, from: data)
        guard let textBlock = decoded.content.first(where: { $0.type == "text" }) else {
            throw GrammarProviderError.invalidResponse
        }
        return GrammarResponse(correctedText: textBlock.text.trimmingCharacters(in: .whitespacesAndNewlines))
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

private struct AnthropicMessagesResponse: Decodable {
    struct ContentBlock: Decodable {
        let type: String
        let text: String
    }
    let content: [ContentBlock]
}
