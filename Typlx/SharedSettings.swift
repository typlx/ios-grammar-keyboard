import Foundation
import Security

// Replace TEAMID with your Apple Developer Team ID (10-character string from the Member Center).
// Both targets must list this access group in their keychain-access-groups entitlement.
// Example: "A1B2C3D4E5.com.typlx.grammar-keyboard"
private let keychainAccessGroup = "TEAMID.com.typlx.grammar-keyboard"
private let keychainService = "com.typlx.grammar-keyboard"

final class SharedSettings {
    static let shared = SharedSettings()
    private init() {}

    var apiURL: String {
        get { load(key: "apiURL") ?? "" }
        set { save(key: "apiURL", value: newValue) }
    }

    var model: String {
        get { load(key: "model") ?? "" }
        set { save(key: "model", value: newValue) }
    }

    var apiToken: String {
        get { load(key: "apiToken") ?? "" }
        set { save(key: "apiToken", value: newValue) }
    }

    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        delete(key: key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: keychainAccessGroup
        ]
        SecItemDelete(query as CFDictionary)
    }
}
