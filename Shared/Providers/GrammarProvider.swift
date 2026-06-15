import Foundation

// Context hint for prompt selection — mirrors the API contract's contextType enum.
public enum ContextType: String, Codable, CaseIterable {
    case general
    case email
    case chat
    case essay
    case codeComment = "code_comment"
}

public enum CorrectionLanguage: String, Codable, CaseIterable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case portuguese = "pt"
    case italian = "it"

    public var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .portuguese: return "Portuguese"
        case .italian: return "Italian"
        }
    }
}

public struct GrammarRequest {
    public let text: String
    public let context: ContextType
    public let language: CorrectionLanguage

    public init(text: String, context: ContextType = .general, language: CorrectionLanguage = .english) {
        self.text = text
        self.context = context
        self.language = language
    }
}

public struct GrammarResponse {
    public let correctedText: String
    public let explanation: String?

    public init(correctedText: String, explanation: String? = nil) {
        self.correctedText = correctedText
        self.explanation = explanation
    }
}

public enum GrammarProviderError: Error, LocalizedError {
    case networkUnavailable
    case unauthorized
    case rateLimited
    case serverError(Int, String)
    case invalidResponse
    case noFullAccess

    public var errorDescription: String? {
        switch self {
        case .networkUnavailable: return "No network access. Enable 'Allow Full Access' in Settings."
        case .unauthorized: return "Invalid API key. Check your settings."
        case .rateLimited: return "Rate limit exceeded. Try again later."
        case .serverError(let code, let msg): return "Server error \(code): \(msg)"
        case .invalidResponse: return "Unexpected response from provider."
        case .noFullAccess: return "Full Access is required for cloud grammar correction."
        }
    }
}

public protocol GrammarProvider: AnyObject {
    var providerId: String { get }
    var displayName: String { get }

    /// Validate that the provider is configured and reachable.
    func validate() async throws

    /// Correct grammar in the given text.
    func correct(_ request: GrammarRequest) async throws -> GrammarResponse
}
