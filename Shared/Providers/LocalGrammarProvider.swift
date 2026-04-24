import Foundation

/// Stub provider for on-device / self-hosted grammar correction.
/// Returns a "coming soon" response until a local model is integrated.
public final class LocalGrammarProvider: GrammarProvider {
    public let providerId = "local"
    public let displayName = "Local (Coming Soon)"

    public init() {}

    public func validate() async throws {
        // Local mode is always "valid" — no network needed.
    }

    public func correct(_ request: GrammarRequest) async throws -> GrammarResponse {
        GrammarResponse(
            correctedText: request.text,
            explanation: "Local grammar correction is coming soon. No changes were made."
        )
    }
}
