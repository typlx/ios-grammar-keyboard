import Foundation

/// Shared constants for App Group and Keychain access group.
/// Both the container app and the keyboard extension must reference the same group IDs.
public enum AppGroupConfig {
    /// App Group identifier registered in both targets' entitlements.
    public static let groupIdentifier = "group.com.typlx.keyboard"

    /// Keychain access group shared between the container app and keyboard extension.
    public static let keychainAccessGroup = "com.typlx.keyboard.shared"

    /// Shared UserDefaults suite backed by the App Group container.
    public static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: groupIdentifier)!
    }
}

// MARK: - SharedDefaults Keys

public extension AppGroupConfig {
    enum DefaultsKey: String {
        case selectedProvider = "selectedProvider"
        case openAIModel = "openAIModel"
        case anthropicModel = "anthropicModel"
        case openAIURL = "openAIURL"
        case anthropicURL = "anthropicURL"
        case processingMode = "processingMode"
        case defaultContext = "defaultContext"
    }

    static func set<T>(_ value: T, for key: DefaultsKey) {
        sharedDefaults.set(value, forKey: key.rawValue)
    }

    static func string(for key: DefaultsKey) -> String? {
        sharedDefaults.string(forKey: key.rawValue)
    }

    static func providerConfig(for type: ProviderType) -> ProviderConfig {
        let keychain = KeychainManager.shared
        switch type {
        case .openAI:
            let apiKey = (try? keychain.loadAPIKey(slot: .openAI)) ?? ""
            let url = string(for: .openAIURL) ?? ProviderConfig.defaultOpenAI.apiURL
            let model = string(for: .openAIModel) ?? ProviderConfig.defaultOpenAI.model
            return ProviderConfig(providerType: .openAI, apiURL: url, model: model, apiKey: apiKey)
        case .anthropic:
            let apiKey = (try? keychain.loadAPIKey(slot: .anthropic)) ?? ""
            let url = string(for: .anthropicURL) ?? ProviderConfig.defaultAnthropic.apiURL
            let model = string(for: .anthropicModel) ?? ProviderConfig.defaultAnthropic.model
            return ProviderConfig(providerType: .anthropic, apiURL: url, model: model, apiKey: apiKey)
        case .local:
            return ProviderConfig.defaultLocal
        }
    }

    static func activeProviderConfig() -> ProviderConfig {
        let typeRaw = string(for: .selectedProvider) ?? ProviderType.openAI.rawValue
        let type = ProviderType(rawValue: typeRaw) ?? .openAI
        return providerConfig(for: type)
    }
}
