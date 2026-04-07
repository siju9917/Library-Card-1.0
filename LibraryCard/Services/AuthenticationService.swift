import Foundation
import AuthenticationServices
import LocalAuthentication
import SwiftUI

/// Result returned after successful Apple Sign In.
struct AppleSignInResult {
    let displayName: String
    let email: String?
    let userIdentifier: String
}

@MainActor
final class AuthenticationService: ObservableObject, Authenticating {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var authError: String?

    private let keychainKey: String

    init(keychainKey: String = "\(Bundle.main.bundleIdentifier ?? "com.librarycard").userIdentifier") {
        self.keychainKey = keychainKey
    }

    // MARK: - Sign in with Apple

    @discardableResult
    func handleSignInWithApple(result: Result<ASAuthorization, Error>, modelContext: Any) -> AppleSignInResult? {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                authError = "Invalid credential type."
                return nil
            }

            let userIdentifier = credential.user
            saveToKeychain(userIdentifier)

            let displayName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            isAuthenticated = true
            authError = nil

            return AppleSignInResult(
                displayName: displayName.isEmpty ? "User" : displayName,
                email: credential.email,
                userIdentifier: userIdentifier
            )

        case .failure(let error):
            AppError.log(.authentication(error.localizedDescription))
            authError = error.localizedDescription
            isAuthenticated = false
            return nil
        }
    }

    // MARK: - Biometric Authentication

    func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            authError = error?.localizedDescription ?? "Biometrics not available on this device."
            return false
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock Library Card"
            )
            if success {
                isAuthenticated = true
            }
            return success
        } catch {
            AppError.log(.authentication(error.localizedDescription))
            authError = error.localizedDescription
            return false
        }
    }

    // MARK: - Check Existing Auth

    func checkExistingAuth() {
        guard let identifier = loadFromKeychain() else { return }

        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: identifier) { [weak self] state, _ in
            Task { @MainActor in
                switch state {
                case .authorized:
                    self?.isAuthenticated = true
                case .revoked, .notFound:
                    self?.isAuthenticated = false
                    self?.removeFromKeychain()
                default:
                    break
                }
            }
        }
    }

    func signOut() {
        removeFromKeychain()
        isAuthenticated = false
        authError = nil
    }

    // MARK: - Keychain Helpers

    private func saveToKeychain(_ value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            AppError.log(.persistence("Keychain save failed with status: \(status)"))
        }
    }

    private func loadFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func removeFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey
        ]
        SecItemDelete(query as CFDictionary)
    }
}
