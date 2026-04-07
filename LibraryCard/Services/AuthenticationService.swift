import Foundation
import AuthenticationServices
import LocalAuthentication
import SwiftUI

@MainActor
final class AuthenticationService: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var authError: String?

    private let keychainKey = "com.librarycard.userIdentifier"

    // MARK: - Sign in with Apple

    func handleSignInWithApple(result: Result<ASAuthorization, Error>, modelContext: Any) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userIdentifier = appleIDCredential.user
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email

                // Store identifier in Keychain
                saveToKeychain(userIdentifier)

                let displayName = [fullName?.givenName, fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")

                isAuthenticated = true
                authError = nil

                // Note: User creation in SwiftData handled by the calling view
                _ = (displayName.isEmpty ? "User" : displayName, email, userIdentifier)
            }
        case .failure(let error):
            authError = error.localizedDescription
            isAuthenticated = false
        }
    }

    // MARK: - Biometric Authentication

    func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            authError = error?.localizedDescription ?? "Biometrics not available"
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
            authError = error.localizedDescription
            return false
        }
    }

    // MARK: - Check Existing Auth

    func checkExistingAuth() {
        if let identifier = loadFromKeychain() {
            // Verify the Apple ID credential state
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
    }

    func signOut() {
        removeFromKeychain()
        isAuthenticated = false
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
        SecItemAdd(query as CFDictionary, nil)
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
