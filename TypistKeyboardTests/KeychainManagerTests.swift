import XCTest
@testable import TypistKeyboard

final class KeychainManagerTests: XCTestCase {

    // Use an empty access group so tests work without an app-group entitlement.
    private var keychain: KeychainManager!
    private let testService = "com.typlx.keyboard"

    override func setUp() {
        super.setUp()
        keychain = KeychainManager(accessGroup: "")
        // Clean up any keys left from a previous run.
        keychain.delete(key: "test.key")
        keychain.delete(key: "test.key.2")
        keychain.deleteAPIKey(slot: .openAI)
        keychain.deleteAPIKey(slot: .anthropic)
    }

    override func tearDown() {
        keychain.delete(key: "test.key")
        keychain.delete(key: "test.key.2")
        keychain.deleteAPIKey(slot: .openAI)
        keychain.deleteAPIKey(slot: .anthropic)
        keychain = nil
        super.tearDown()
    }

    // MARK: - Basic save / load / delete

    func testSaveAndLoadValue() throws {
        try keychain.save(key: "test.key", value: "secret-value")
        let loaded = try keychain.load(key: "test.key")
        XCTAssertEqual(loaded, "secret-value")
    }

    func testLoadReturnsNilForAbsentKey() throws {
        let result = try keychain.load(key: "nonexistent.\(UUID().uuidString)")
        XCTAssertNil(result, "Loading a missing key should return nil, not throw")
    }

    func testSaveOverwritesPreviousValue() throws {
        try keychain.save(key: "test.key", value: "first")
        try keychain.save(key: "test.key", value: "second")
        let loaded = try keychain.load(key: "test.key")
        XCTAssertEqual(loaded, "second", "Save should overwrite the existing value")
    }

    func testDeleteReturnsTrueWhenKeyExists() throws {
        try keychain.save(key: "test.key", value: "val")
        let deleted = keychain.delete(key: "test.key")
        XCTAssertTrue(deleted, "Delete should return true for an existing key")
    }

    func testDeleteReturnsFalseForAbsentKey() {
        let result = keychain.delete(key: "nonexistent.\(UUID().uuidString)")
        XCTAssertFalse(result, "Delete should return false when the key does not exist")
    }

    func testLoadAfterDeleteReturnsNil() throws {
        try keychain.save(key: "test.key", value: "hello")
        keychain.delete(key: "test.key")
        let loaded = try keychain.load(key: "test.key")
        XCTAssertNil(loaded, "Key should be absent after deletion")
    }

    func testSaveAndLoadUnicodeValue() throws {
        let unicode = "Héllo Wörld 🌍"
        try keychain.save(key: "test.key", value: unicode)
        let loaded = try keychain.load(key: "test.key")
        XCTAssertEqual(loaded, unicode, "Unicode strings should round-trip correctly through Keychain")
    }

    func testTwoIndependentKeys() throws {
        try keychain.save(key: "test.key", value: "alpha")
        try keychain.save(key: "test.key.2", value: "beta")

        XCTAssertEqual(try keychain.load(key: "test.key"), "alpha")
        XCTAssertEqual(try keychain.load(key: "test.key.2"), "beta")
    }

    // MARK: - Typed API key accessors

    func testSaveAndLoadOpenAIKey() throws {
        try keychain.saveAPIKey("sk-openai-123", slot: .openAI)
        let loaded = try keychain.loadAPIKey(slot: .openAI)
        XCTAssertEqual(loaded, "sk-openai-123")
    }

    func testSaveAndLoadAnthropicKey() throws {
        try keychain.saveAPIKey("sk-ant-456", slot: .anthropic)
        let loaded = try keychain.loadAPIKey(slot: .anthropic)
        XCTAssertEqual(loaded, "sk-ant-456")
    }

    func testOpenAIAndAnthropicSlotsAreIndependent() throws {
        try keychain.saveAPIKey("openai-key", slot: .openAI)
        try keychain.saveAPIKey("anthropic-key", slot: .anthropic)
        XCTAssertEqual(try keychain.loadAPIKey(slot: .openAI), "openai-key")
        XCTAssertEqual(try keychain.loadAPIKey(slot: .anthropic), "anthropic-key")
    }

    func testDeleteAPIKeyMakesLoadReturnNil() throws {
        try keychain.saveAPIKey("sk-openai-to-delete", slot: .openAI)
        keychain.deleteAPIKey(slot: .openAI)
        let loaded = try keychain.loadAPIKey(slot: .openAI)
        XCTAssertNil(loaded, "loadAPIKey should return nil after deleteAPIKey")
    }

    func testLoadAPIKeyReturnsNilWhenNeverSaved() throws {
        let loaded = try keychain.loadAPIKey(slot: .anthropic)
        XCTAssertNil(loaded, "loadAPIKey should return nil if the slot was never saved")
    }

    func testAPIKeySlotRawValues() {
        XCTAssertEqual(KeychainManager.APIKeySlot.openAI.rawValue, "apiKey.openai")
        XCTAssertEqual(KeychainManager.APIKeySlot.anthropic.rawValue, "apiKey.anthropic")
    }

    // MARK: - KeychainError descriptions

    func testEncodingFailedHasDescription() {
        XCTAssertFalse(KeychainError.encodingFailed.errorDescription?.isEmpty ?? true)
    }

    func testDecodingFailedHasDescription() {
        XCTAssertFalse(KeychainError.decodingFailed.errorDescription?.isEmpty ?? true)
    }

    func testSaveFailedIncludesOSStatus() {
        let desc = KeychainError.saveFailed(-25299).errorDescription ?? ""
        XCTAssertTrue(desc.contains("-25299"), "saveFailed description should include the OSStatus")
    }

    func testLoadFailedIncludesOSStatus() {
        let desc = KeychainError.loadFailed(-25300).errorDescription ?? ""
        XCTAssertTrue(desc.contains("-25300"), "loadFailed description should include the OSStatus")
    }
}
