import Foundation

/// Protocol for transaction classification.
/// Enables dependency injection and testability.
protocol TransactionClassifying {
    func isDrinkRelated(merchantCategoryCode: String?) -> Bool
    func classify(_ transaction: TransactionDTO) -> ClassificationResult
    func estimateDrinkCount(amount: Double, averageDrinkPrice: Double) -> Int
}
