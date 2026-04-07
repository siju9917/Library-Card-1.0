import Foundation

/// Classifies incoming transactions to determine if they are drink-related
/// and auto-creates Drink records when possible.
struct TransactionClassifier: TransactionClassifying {

    /// All MCC codes related to alcohol/dining
    static let drinkMCCs: Set<String> = [
        "5813", // Bars, Cocktail Lounges, Taverns, Nightclubs
        "5812", // Eating Places, Restaurants
        "5921", // Package Stores, Beer, Wine, Liquor
        "5811", // Caterers
        "5814", // Fast Food Restaurants
        "7032", // Sporting and Recreation Camps (often have bars)
        "7995", // Gambling (casinos have bars)
    ]

    /// High-confidence bar/tavern MCC codes
    static let definiteBarMCCs: Set<String> = [
        "5813", // Bars, Cocktail Lounges, Taverns
        "5921", // Package Stores, Beer, Wine, Liquor
    ]

    func isDrinkRelated(merchantCategoryCode: String?) -> Bool {
        guard let mcc = merchantCategoryCode else { return false }
        return Self.drinkMCCs.contains(mcc)
    }

    func classify(_ transaction: TransactionDTO) -> ClassificationResult {
        let mcc = transaction.merchantCategoryCode ?? ""

        if Self.definiteBarMCCs.contains(mcc) {
            return ClassificationResult(
                isDrinkPurchase: true,
                confidence: .high,
                suggestedDrinkType: nil,
                category: mcc == "5921" ? .liquorStore : .barOrTavern
            )
        }

        if mcc == "5812" || mcc == "5814" {
            return ClassificationResult(
                isDrinkPurchase: false,
                confidence: .medium,
                suggestedDrinkType: nil,
                category: .restaurant
            )
        }

        if mcc == "5811" {
            return ClassificationResult(
                isDrinkPurchase: false,
                confidence: .low,
                suggestedDrinkType: nil,
                category: .caterer
            )
        }

        return ClassificationResult(
            isDrinkPurchase: false,
            confidence: .high,
            suggestedDrinkType: nil,
            category: .other
        )
    }

    func estimateDrinkCount(amount: Double, averageDrinkPrice: Double = 8.0) -> Int {
        guard amount > 0, averageDrinkPrice > 0 else { return 0 }
        return max(1, Int(round(amount / averageDrinkPrice)))
    }
}

struct ClassificationResult {
    let isDrinkPurchase: Bool
    let confidence: Confidence
    let suggestedDrinkType: DrinkType?
    let category: MerchantCategory

    enum Confidence: String {
        case high = "High"
        case medium = "Medium"
        case low = "Low"
    }

    enum MerchantCategory: String {
        case barOrTavern = "Bar/Tavern"
        case restaurant = "Restaurant"
        case liquorStore = "Liquor Store"
        case caterer = "Caterer"
        case other = "Other"
    }
}
