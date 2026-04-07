import Foundation
import AuthenticationServices

/// Protocol for authentication operations.
/// Enables dependency injection and testability.
@MainActor
protocol Authenticating: ObservableObject {
    var isAuthenticated: Bool { get }
    var isLoading: Bool { get }
    var authError: String? { get }

    func handleSignInWithApple(result: Result<ASAuthorization, Error>, modelContext: Any)
    func authenticateWithBiometrics() async -> Bool
    func checkExistingAuth()
    func signOut()
}
