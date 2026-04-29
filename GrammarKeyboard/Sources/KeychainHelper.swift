import Foundation
import Security

/// A lightweight wrapper around the iOS Keychain for storing and retrieving
/// string values. Uses kSecAttrAccessGroup with the app group so the keyboard
/// extension can share credentials with the host app.
enum KeychainHelper {
    static let tokenKey = "com.typlx.grammar-keyboard.api-token"
    static let accessGroup = "group.com.typlx.grammar-keyboard"

    // MARK: - Save

    /// Saves a string value to the Keychain. Updates the existing item if one
    /// already exists for the given key.
    @discardableResult
    static func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Delete any existing item first to avoid duplicates.
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: accessGroup,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Load

    /// Loads a string value from the Keychain for the given key.
    /// Returns `nil` if the item does not exist or cannot be read.
    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: accessGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Delete

    /// Deletes the Keychain item for the given key.
    @discardableResult
    static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: accessGroup
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
