import Foundation

/// RevenueCat SDK configuration.
///
/// Leave `apiKey` empty until the key is available (TYP-124).
/// The key will be injected via environment/secrets at build time — never hard-code it here.
public enum RevenueCatConfig {
    /// Placeholder — replace with the real App Store API key when available.
    public static let apiKey: String = ""

    public static var isConfigured: Bool {
        !apiKey.isEmpty
    }
}
