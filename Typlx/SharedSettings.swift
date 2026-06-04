import Foundation
import Security

private let keychainService = "com.typlx.grammar-keyboard"

// Reads the Team ID prefix injected by Xcode at build time via Info.plist AppIdentifierPrefix key.
// Returns nil when building without a provisioning profile (simulator/unsigned builds).
private var keychainAccessGroup: String? {
    guard let prefix = Bundle.main.infoDictionary?["AppIdentifierPrefix"] as? String,
          !prefix.isEmpty, prefix != "." else { return nil }
    return "\(prefix)com.typlx.grammar-keyboard"
}

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
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        if let group = keychainAccessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        SecItemAdd(query as CFDictionary, nil)
    }

    private func load(key: String) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        if let group = keychainAccessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(key: String) {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
        ]
        if let group = keychainAccessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        SecItemDelete(query as CFDictionary)
    }
}
