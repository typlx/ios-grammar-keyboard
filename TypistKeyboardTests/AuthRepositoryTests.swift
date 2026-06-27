import XCTest
@testable import TypistKeyboard

final class AuthRepositoryTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        await AuthRepository.shared.logout()
    }

    // MARK: - State management

    func testIsLoggedOutAfterLogout() async {
        await AuthRepository.shared.logout()
        XCTAssertFalse(AuthRepository.shared.isLoggedIn)
        XCTAssertNil(AuthRepository.shared.currentSession)
    }

    func testCurrentSessionIsNilInitially() async {
        await AuthRepository.shared.logout()
        XCTAssertNil(AuthRepository.shared.currentSession)
    }

    // MARK: - Login stub

    func testLoginThrowsNotConfigured() async {
        do {
            _ = try await AuthRepository.shared.login(email: "test@example.com", password: "hunter2")
            XCTFail("Expected AuthError.notConfigured to be thrown")
        } catch AuthError.notConfigured {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testLoginDoesNotAlterSessionOnFailure() async {
        _ = try? await AuthRepository.shared.login(email: "user@example.com", password: "pass")
        XCTAssertFalse(AuthRepository.shared.isLoggedIn, "Session should not be set when login stub fails")
    }

    // MARK: - Session persistence

    func testPersistAndRestoreSession() {
        let session = UserSession(userId: "u1", accessToken: "tok_abc", refreshToken: "ref_xyz")
        AuthRepository.shared.persistSession(session)
        XCTAssertTrue(AuthRepository.shared.isLoggedIn)
        XCTAssertEqual(AuthRepository.shared.currentSession?.accessToken, "tok_abc")
    }

    func testClearSessionRemovesCurrentSession() {
        let session = UserSession(userId: "u2", accessToken: "tok_def", refreshToken: "ref_uvw")
        AuthRepository.shared.persistSession(session)
        AuthRepository.shared.clearSession()
        XCTAssertFalse(AuthRepository.shared.isLoggedIn)
        XCTAssertNil(AuthRepository.shared.currentSession)
    }
}
