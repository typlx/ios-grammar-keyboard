import Foundation
import Security

/// Stores and retrieves API tokens using iOS Keychain.
/// Uses kSecAttrAccessibleWhenUnlockedThisDeviceOnly for security.
public final class KeychainManager {
    public static let shared = KeychainManager()

    // App Group identifier shared between the container app and keyboard extension.
    // Must match the App Group registered in both targets' entitlements.
    private let accessGroup: String

    public init(accessGroup: String = AppGroupConfig.keychainAccessGroup) {
        self.accessGroup = accessGroup
    }

    public func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        // Delete any existing item before inserting.
        delete(key: key)

        var query = baseQuery(for: key)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    public func load(key: String) throws -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data, let string = String(data: data, encoding: .utf8) else {
                throw KeychainError.decodingFailed
            }
            return string
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.loadFailed(status)
        }
    }

    @discardableResult
    public func delete(key: String) -> Bool {
        let query = baseQuery(for: key)
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    private func baseQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.typlx.keyboard",
            kSecAttrAccount as String: key
        ]
        if !accessGroup.isEmpty {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }
}

public enum KeychainError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .encodingFailed: return "Failed to encode value for Keychain."
        case .decodingFailed: return "Failed to decode value from Keychain."
        case .saveFailed(let s): return "Keychain save failed: OSStatus \(s)."
        case .loadFailed(let s): return "Keychain load failed: OSStatus \(s)."
        }
    }
}

// MARK: - Typed API key accessors

public extension KeychainManager {
    enum APIKeySlot: String {
        case openAI = "apiKey.openai"
        case anthropic = "apiKey.anthropic"
    }

    func saveAPIKey(_ key: String, slot: APIKeySlot) throws {
        try save(key: slot.rawValue, value: key)
    }

    func loadAPIKey(slot: APIKeySlot) throws -> String? {
        try load(key: slot.rawValue)
    }

    func deleteAPIKey(slot: APIKeySlot) {
        delete(key: slot.rawValue)
    }
}
