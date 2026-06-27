import XCTest
@testable import TypistKeyboard

final class PurchaseManagerTests: XCTestCase {

    // MARK: - checkEntitlement stub

    func testCheckEntitlementReturnsFalseWhenNotConfigured() async {
        let result = await PurchaseManager.shared.checkEntitlement(.premium)
        XCTAssertFalse(result, "Stub should return false when RevenueCat is not configured")
    }

    func testCheckAllEntitlementsReturnFalse() async {
        let identifiers: [EntitlementIdentifier] = [.premium, .advancedGrammar, .toneSuggestions, .multiLanguage]
        for identifier in identifiers {
            let result = await PurchaseManager.shared.checkEntitlement(identifier)
            XCTAssertFalse(result, "\(identifier.rawValue) should return false in stub mode")
        }
    }

    // MARK: - purchase stub

    func testPurchaseThrowsNotConfigured() async {
        do {
            try await PurchaseManager.shared.purchase(productId: "com.typlx.keyboard.premium")
            XCTFail("Expected PurchaseError.notConfigured to be thrown")
        } catch PurchaseError.notConfigured {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - restorePurchases stub

    func testRestorePurchasesThrowsNotConfigured() async {
        do {
            try await PurchaseManager.shared.restorePurchases()
            XCTFail("Expected PurchaseError.notConfigured to be thrown")
        } catch PurchaseError.notConfigured {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - configure no-op

    func testConfigureWithEmptyKeyIsNoOp() {
        // Should not crash or throw
        PurchaseManager.shared.configure(apiKey: "")
    }
}
