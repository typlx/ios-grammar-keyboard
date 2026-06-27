import Foundation

/// Entitlement identifiers that map to RevenueCat product entitlements.
public enum EntitlementIdentifier: String {
    case premium = "premium"
    case advancedGrammar = "advanced_grammar"
    case toneSuggestions = "tone_suggestions"
    case multiLanguage = "multi_language"
}

public enum PurchaseError: Error, LocalizedError {
    case notConfigured
    case purchaseCancelled
    case purchaseFailed(String)
    case networkUnavailable

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "RevenueCat is not configured. Provide an API key via RevenueCatConfig."
        case .purchaseCancelled:
            return "Purchase was cancelled by the user."
        case .purchaseFailed(let msg):
            return "Purchase failed: \(msg)"
        case .networkUnavailable:
            return "Network unavailable. Check your connection and try again."
        }
    }
}

/// Stub purchase manager backed by RevenueCat.
///
/// All methods are no-ops until a real API key is configured (TYP-124).
/// Replace TODO blocks with `import RevenueCat` + live SDK calls when keys are available.
public final class PurchaseManager {
    public static let shared = PurchaseManager()

    private init() {}

    /// Configure the RevenueCat SDK. Call once from AppDelegate when the real API key lands.
    public func configure(apiKey: String) {
        guard !apiKey.isEmpty else { return }
        // TODO (TYP-124): Purchases.configure(withAPIKey: apiKey)
    }

    /// Returns whether the user holds the given entitlement.
    /// Stub always returns `false`; FeatureGate passthrough overrides this for now.
    public func checkEntitlement(_ identifier: EntitlementIdentifier) async -> Bool {
        // TODO (TYP-124):
        // guard let info = try? await Purchases.shared.customerInfo() else { return false }
        // return info.entitlements[identifier.rawValue]?.isActive == true
        return false
    }

    /// Initiate an in-app purchase for the given product ID.
    /// Stub throws `notConfigured` until RevenueCat is wired up (TYP-124).
    public func purchase(productId: String) async throws {
        // TODO (TYP-124):
        // let products = try await Purchases.shared.products([productId])
        // guard let product = products.first else { throw PurchaseError.purchaseFailed("Product not found") }
        // let result = try await Purchases.shared.purchase(product: product)
        // if result.userCancelled { throw PurchaseError.purchaseCancelled }
        throw PurchaseError.notConfigured
    }

    /// Restore prior purchases for the current user.
    /// Stub throws `notConfigured` until RevenueCat is wired up (TYP-124).
    public func restorePurchases() async throws {
        // TODO (TYP-124): _ = try await Purchases.shared.restorePurchases()
        throw PurchaseError.notConfigured
    }
}
