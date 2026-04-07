import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var externalId: String?
    var amount: Double
    var currency: String
    var merchantName: String
    var merchantCategory: String?
    var merchantCategoryCode: String?
    var merchantCity: String?
    var merchantCountry: String?
    var timestamp: Date
    var isDrinkPurchase: Bool
    var isConfirmedByUser: Bool
    var cardLastFour: String?
    var usedApplePay: Bool

    var session: DrinkingSession?

    init(
        amount: Double,
        currency: String = "USD",
        merchantName: String,
        merchantCategory: String? = nil,
        merchantCategoryCode: String? = nil,
        merchantCity: String? = nil,
        merchantCountry: String? = nil,
        isDrinkPurchase: Bool = false,
        cardLastFour: String? = nil,
        usedApplePay: Bool = false,
        session: DrinkingSession? = nil
    ) {
        self.id = UUID()
        self.externalId = nil
        self.amount = amount
        self.currency = currency
        self.merchantName = merchantName
        self.merchantCategory = merchantCategory
        self.merchantCategoryCode = merchantCategoryCode
        self.merchantCity = merchantCity
        self.merchantCountry = merchantCountry
        self.timestamp = Date()
        self.isDrinkPurchase = isDrinkPurchase
        self.isConfirmedByUser = false
        self.cardLastFour = cardLastFour
        self.usedApplePay = usedApplePay
        self.session = session
    }

    /// MCC codes that indicate bar/restaurant purchases
    static let drinkRelatedMCCs: Set<String> = [
        "5813", // Bars, Cocktail Lounges, Taverns
        "5812", // Eating Places, Restaurants
        "5921", // Package Stores, Beer, Wine, Liquor
        "5811", // Caterers
        "5814", // Fast Food Restaurants
    ]

    var isLikelyDrinkPurchase: Bool {
        guard let mcc = merchantCategoryCode else { return false }
        return Transaction.drinkRelatedMCCs.contains(mcc)
    }

    var amountFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(String(format: "%.2f", amount))"
    }
}
