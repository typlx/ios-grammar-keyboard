import Foundation

public enum ProviderType: String, Codable, CaseIterable {
    case openAI = "openai"
    case anthropic = "anthropic"
    case local = "local"
}

public struct ProviderConfig: Codable, Equatable {
    public var providerType: ProviderType
    public var apiURL: String
    public var model: String
    public var apiKey: String

    public init(providerType: ProviderType, apiURL: String, model: String, apiKey: String) {
        self.providerType = providerType
        self.apiURL = apiURL
        self.model = model
        self.apiKey = apiKey
    }
}

extension ProviderConfig {
    public static var defaultOpenAI: ProviderConfig {
        ProviderConfig(
            providerType: .openAI,
            apiURL: "https://api.openai.com/v1/chat/completions",
            model: "gpt-4o-mini",
            apiKey: ""
        )
    }

    public static var defaultAnthropic: ProviderConfig {
        ProviderConfig(
            providerType: .anthropic,
            apiURL: "https://api.anthropic.com/v1/messages",
            model: "claude-haiku-4-5-20251001",
            apiKey: ""
        )
    }

    public static var defaultLocal: ProviderConfig {
        ProviderConfig(
            providerType: .local,
            apiURL: "",
            model: "local",
            apiKey: ""
        )
    }
}

public final class ProviderRegistry {
    public static let shared = ProviderRegistry()

    private init() {}

    public func makeProvider(config: ProviderConfig) -> any GrammarProvider {
        switch config.providerType {
        case .openAI:
            return OpenAIProvider(config: config)
        case .anthropic:
            return AnthropicProvider(config: config)
        case .local:
            return LocalGrammarProvider()
        }
    }
}
