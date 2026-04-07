import Foundation

/// Classifies incoming transactions to determine if they are drink-related
/// and auto-creates Drink records when possible.
struct TransactionClassifier {

    /// Determine if a transaction is likely a drink purchase based on MCC code
    static func isDrinkRelated(merchantCategoryCode: String?) -> Bool {
        guard let mcc = merchantCategoryCode else { return false }
        return Transaction.drinkRelatedMCCs.contains(mcc)
    }

    /// Classify a transaction and return a suggested drink entry
    static func classify(_ transaction: TransactionDTO) -> ClassificationResult {
        let mcc = transaction.merchantCategoryCode ?? ""

        // Direct bar/tavern MCC
        if mcc == "5813" {
            return ClassificationResult(
                isDrinkPurchase: true,
                confidence: .high,
                suggestedDrinkType: nil, // Can't determine type from transaction
                category: .barOrTavern
            )
        }

        // Restaurant
        if mcc == "5812" || mcc == "5814" {
            return ClassificationResult(
                isDrinkPurchase: false, // Could be food or drinks
                confidence: .medium,
                suggestedDrinkType: nil,
                category: .restaurant
            )
        }

        // Liquor store
        if mcc == "5921" {
            return ClassificationResult(
                isDrinkPurchase: true,
                confidence: .high,
                suggestedDrinkType: nil,
                category: .liquorStore
            )
        }

        // Not drink-related
        return ClassificationResult(
            isDrinkPurchase: false,
            confidence: .high,
            suggestedDrinkType: nil,
            category: .other
        )
    }

    /// Estimate number of drinks from a bar transaction amount
    static func estimateDrinkCount(amount: Double, averageDrinkPrice: Double = 8.0) -> Int {
        guard amount > 0, averageDrinkPrice > 0 else { return 0 }
        return max(1, Int(round(amount / averageDrinkPrice)))
    }
}

struct ClassificationResult {
    let isDrinkPurchase: Bool
    let confidence: Confidence
    let suggestedDrinkType: DrinkType?
    let category: MerchantCategory

    enum Confidence {
        case high
        case medium
        case low
    }

    enum MerchantCategory {
        case barOrTavern
        case restaurant
        case liquorStore
        case caterer
        case other
    }
}
