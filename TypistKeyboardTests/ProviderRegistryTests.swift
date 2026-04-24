import XCTest
@testable import TypistKeyboard

final class ProviderRegistryTests: XCTestCase {

    func testMakesOpenAIProvider() {
        let config = ProviderConfig.defaultOpenAI
        let provider = ProviderRegistry.shared.makeProvider(config: config)
        XCTAssertEqual(provider.providerId, "openai")
    }

    func testMakesAnthropicProvider() {
        let config = ProviderConfig.defaultAnthropic
        let provider = ProviderRegistry.shared.makeProvider(config: config)
        XCTAssertEqual(provider.providerId, "anthropic")
    }

    func testMakesLocalProvider() {
        let config = ProviderConfig.defaultLocal
        let provider = ProviderRegistry.shared.makeProvider(config: config)
        XCTAssertEqual(provider.providerId, "local")
    }
}
