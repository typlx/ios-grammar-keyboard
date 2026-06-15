import Foundation

final class APIService {
    static let shared = APIService()
    private init() {}

    private let systemPrompt = "Fix grammar and spelling in the following text. Return only the corrected text, nothing else. Preserve the original language, tone, and formatting."
    private let temperature: Double = 0.3
    private let timeout: TimeInterval = 30

    enum APIError: LocalizedError {
        case invalidURL
        case httpError(Int)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid API URL"
            case .httpError(let code): return "HTTP error \(code)"
            case .invalidResponse: return "Unexpected response format"
            }
        }
    }

    func fixGrammar(text: String) async throws -> String {
        let settings = SharedSettings.shared
        let baseURL = settings.apiURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let endpoint: String
        if baseURL.hasSuffix("/chat/completions") {
            endpoint = baseURL
        } else if let components = URLComponents(string: baseURL),
                  components.path.isEmpty || components.path == "/" {
            // Bare host — standard OpenAI-compatible APIs require /v1 before the path.
            endpoint = baseURL + "/v1/chat/completions"
        } else {
            endpoint = baseURL + "/chat/completions"
        }

        guard let url = URL(string: endpoint) else { throw APIError.invalidURL }

        let body: [String: Any] = [
            "model": settings.model,
            "temperature": temperature,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ]
        ]

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(settings.apiToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.httpError(http.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String
        else { throw APIError.invalidResponse }

        return content
    }
}
