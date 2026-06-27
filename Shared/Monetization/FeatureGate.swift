import Foundation

/// Premium feature identifiers — used to gate functionality until real entitlements are wired.
/// See TYP-124 for entitlement wiring.
public enum PremiumFeature: String, CaseIterable {
    case advancedGrammar = "ADVANCED_GRAMMAR"
    case toneSuggestions = "TONE_SUGGESTIONS"
    case multiLanguage = "MULTI_LANGUAGE"
}

/// Central feature-flag gate for premium features.
///
/// Passthrough mode is on by default: all features report as enabled so the app works
/// end-to-end before real RevenueCat entitlements are connected (TYP-124).
public final class FeatureGate {
    public static let shared = FeatureGate()

    private var passthroughEnabled: Bool = true

    private init() {}

    /// Returns whether `feature` is currently available to the user.
    public func isEnabled(_ feature: PremiumFeature) -> Bool {
        if passthroughEnabled { return true }
        // TODO (TYP-124): delegate to PurchaseManager.shared.checkEntitlement(...)
        return false
    }

    /// Flip passthrough for testing and for TYP-124 entitlement wiring.
    internal func setPassthrough(_ enabled: Bool) {
        passthroughEnabled = enabled
    }
}
