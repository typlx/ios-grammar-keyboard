import Foundation

/// Minimal representation of an authenticated user session.
public struct UserSession {
    public let userId: String
    public let accessToken: String
    public let refreshToken: String

    public init(userId: String, accessToken: String, refreshToken: String) {
        self.userId = userId
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

public enum AuthError: Error, LocalizedError {
    case notConfigured
    case invalidCredentials
    case sessionExpired
    case networkUnavailable

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase client is not configured. Provide credentials via environment."
        case .invalidCredentials:
            return "Invalid email or password."
        case .sessionExpired:
            return "Session has expired. Please log in again."
        case .networkUnavailable:
            return "Network unavailable."
        }
    }
}

/// Stub auth repository backed by Supabase.
///
/// All network methods are no-ops until Supabase credentials are available (TYP-124).
/// Token storage uses the shared KeychainManager for cross-target access.
public final class AuthRepository {
    public static let shared = AuthRepository()

    private let keychain = KeychainManager.shared
    private static let sessionTokenKey = "auth.session.accessToken"

    /// The current active session, or `nil` if the user is logged out.
    public private(set) var currentSession: UserSession?

    private init() {
        restoreSession()
    }

    // MARK: - Auth stubs

    /// Sign in with email and password.
    /// Stub always throws `notConfigured` until Supabase is wired (TYP-124).
    public func login(email: String, password: String) async throws -> UserSession {
        // TODO (TYP-124):
        // let session = try await supabase.auth.signIn(email: email, password: password)
        // let userSession = UserSession(userId: session.user.id.uuidString,
        //                              accessToken: session.accessToken,
        //                              refreshToken: session.refreshToken)
        // persistSession(userSession)
        // return userSession
        throw AuthError.notConfigured
    }

    /// Sign out the current user and clear the stored session.
    public func logout() async {
        // TODO (TYP-124): try? await supabase.auth.signOut()
        clearSession()
    }

    // MARK: - Session state

    public var isLoggedIn: Bool {
        currentSession != nil
    }

    // MARK: - Token storage

    private func restoreSession() {
        guard let token = try? keychain.load(key: Self.sessionTokenKey), !token.isEmpty else { return }
        currentSession = UserSession(userId: "", accessToken: token, refreshToken: "")
    }

    func persistSession(_ session: UserSession) {
        try? keychain.save(key: Self.sessionTokenKey, value: session.accessToken)
        currentSession = session
    }

    func clearSession() {
        keychain.delete(key: Self.sessionTokenKey)
        currentSession = nil
    }
}
