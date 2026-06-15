import Foundation

/// Calls a chat-completions-compatible API to fix grammar and spelling.
/// Configuration (API URL, model, token) is read from the shared App Group
/// UserDefaults and Keychain so both the host app and the keyboard extension
/// use the same settings.
final class GrammarService {
    // MARK: - Types

    struct GrammarError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    // MARK: - Private constants

    private static let suiteName = "group.com.typlx.grammar-keyboard"
    private static let systemPrompt = """
        Fix grammar and spelling in the following text. \
        Return only the corrected text, nothing else. \
        Preserve the original language, tone, and formatting.
        """
    private static let timeoutInterval: TimeInterval = 30

    // MARK: - Public API

    /// Sends `text` to the configured LLM endpoint for grammar correction.
    /// Returns the corrected text on success.
    /// Throws `GrammarError` with a user-facing message on failure.
    static func fixGrammar(_ text: String) async throws -> String {
        let config = try loadConfiguration()
        let request = try buildRequest(text: text, config: config)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GrammarError(message: "Invalid server response.")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw GrammarError(
                message: "Server returned HTTP \(httpResponse.statusCode). \(body)"
            )
        }

        return try parseResponse(data)
    }

    // MARK: - Configuration

    private struct Configuration {
        let apiUrl: String
        let model: String
        let token: String
    }

    private static func loadConfiguration() throws -> Configuration {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw GrammarError(message: "Cannot access shared settings.")
        }

        guard let apiUrl = defaults.string(forKey: "apiUrl"), !apiUrl.isEmpty else {
            throw GrammarError(message: "API URL is not configured. Open the Typlx app to set it up.")
        }

        guard let model = defaults.string(forKey: "model"), !model.isEmpty else {
            throw GrammarError(message: "Model is not configured. Open the Typlx app to set it up.")
        }

        guard let token = KeychainHelper.load(key: KeychainHelper.tokenKey), !token.isEmpty else {
            throw GrammarError(message: "API token is not configured. Open the Typlx app to set it up.")
        }

        return Configuration(apiUrl: apiUrl, model: model, token: token)
    }

    // MARK: - Request Building

    private static func buildRequest(text: String, config: Configuration) throws -> URLRequest {
        // Strip trailing slashes, then append the chat completions path.
        // For bare hosts (no path component), standard OpenAI-compatible APIs require /v1 first.
        let base = config.apiUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let endpoint: String
        if base.hasSuffix("/chat/completions") {
            endpoint = base
        } else if let components = URLComponents(string: base),
                  components.path.isEmpty || components.path == "/" {
            endpoint = base + "/v1/chat/completions"
        } else {
            endpoint = base + "/chat/completions"
        }

        guard let url = URL(string: endpoint) else {
            throw GrammarError(message: "Invalid API URL: \(endpoint)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.3
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    // MARK: - Response Parsing

    private static func parseResponse(_ data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String
        else {
            throw GrammarError(message: "Unexpected response format from server.")
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
