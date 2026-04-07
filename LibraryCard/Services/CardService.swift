import Foundation

/// Service layer for card issuing operations (Lithic/Stripe integration).
/// This is a placeholder that defines the interface. The actual API calls
/// will be implemented when the card issuing platform is integrated.
@MainActor
final class CardService: ObservableObject {
    @Published var isCardActive: Bool = false
    @Published var cardLastFour: String?
    @Published var cardBalance: Double?
    @Published var isLoading: Bool = false
    @Published var error: String?

    // MARK: - Card Lifecycle

    /// Request a new virtual card from the issuing platform
    func requestCard() async throws -> CardInfo {
        isLoading = true
        defer { isLoading = false }

        // TODO: Implement Lithic API call
        // POST /cards { type: "VIRTUAL", ... }
        // Returns card token, last four, expiry, etc.
        throw CardServiceError.notImplemented
    }

    /// Load funds onto the prepaid card
    func loadFunds(amount: Double) async throws {
        isLoading = true
        defer { isLoading = false }

        // TODO: Implement funding source API call
        throw CardServiceError.notImplemented
    }

    /// Freeze/unfreeze the card
    func setCardState(active: Bool) async throws {
        isLoading = true
        defer { isLoading = false }

        // TODO: Implement card state change
        // PATCH /cards/{token} { state: "OPEN" | "PAUSED" }
        throw CardServiceError.notImplemented
    }

    /// Get current card details and balance
    func refreshCardInfo() async throws -> CardInfo {
        isLoading = true
        defer { isLoading = false }

        // TODO: Implement card info fetch
        throw CardServiceError.notImplemented
    }

    // MARK: - Apple Wallet Provisioning

    /// Initiate Apple Pay provisioning for the card.
    /// Requires the In-App Provisioning entitlement from Apple.
    func provisionForAppleWallet(
        nonce: Data,
        nonceSignature: Data,
        certificates: [Data]
    ) async throws -> ApplePayProvisioningData {
        // TODO: Implement provisioning API call
        // The flow:
        // 1. App presents PKAddPaymentPassViewController
        // 2. Apple provides nonce + certificates via delegate
        // 3. We send those to our backend -> card issuer API
        // 4. Issuer returns encrypted pass data
        // 5. We pass it back to Apple to complete provisioning
        throw CardServiceError.notImplemented
    }

    // MARK: - Transactions

    /// Fetch recent transactions from the card issuer
    func fetchTransactions(limit: Int = 50) async throws -> [TransactionDTO] {
        // TODO: Implement transaction list fetch
        // GET /transactions?card_token=xxx&limit=50
        throw CardServiceError.notImplemented
    }
}

// MARK: - Data Types

struct CardInfo {
    let token: String
    let lastFour: String
    let expiryMonth: Int
    let expiryYear: Int
    let state: CardState
    let balance: Double?
    let type: String // "VIRTUAL" or "PHYSICAL"
}

enum CardState: String {
    case open = "OPEN"
    case paused = "PAUSED"
    case closed = "CLOSED"
    case pendingActivation = "PENDING_ACTIVATION"
}

struct ApplePayProvisioningData {
    let activationData: Data
    let encryptedPassData: Data
    let ephemeralPublicKey: Data
}

struct TransactionDTO {
    let id: String
    let amount: Double
    let currency: String
    let merchantName: String
    let merchantCategory: String?
    let merchantCategoryCode: String?
    let merchantCity: String?
    let merchantCountry: String?
    let timestamp: Date
    let status: String
}

enum CardServiceError: LocalizedError {
    case notImplemented
    case networkError(String)
    case authenticationRequired
    case cardNotFound
    case insufficientFunds

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Card services are not yet configured. This feature will be available when the card issuing platform is integrated."
        case .networkError(let message):
            return "Network error: \(message)"
        case .authenticationRequired:
            return "Please sign in to access card services."
        case .cardNotFound:
            return "No card found. Please set up your Library Card first."
        case .insufficientFunds:
            return "Insufficient funds on your card."
        }
    }
}
