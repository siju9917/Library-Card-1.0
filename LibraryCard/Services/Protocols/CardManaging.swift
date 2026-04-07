import Foundation

/// Protocol for card issuing operations.
/// Enables dependency injection and testability.
@MainActor
protocol CardManaging: ObservableObject {
    var isCardActive: Bool { get }
    var cardLastFour: String? { get }
    var cardBalance: Double? { get }
    var isLoading: Bool { get }
    var error: String? { get }

    func requestCard() async throws -> CardInfo
    func loadFunds(amount: Double) async throws
    func setCardState(active: Bool) async throws
    func refreshCardInfo() async throws -> CardInfo
    func fetchTransactions(limit: Int) async throws -> [TransactionDTO]
}
