import Testing
import Foundation
@testable import LibraryCard

@Suite("Transaction Classifier Tests")
struct TransactionClassifierTests {
    let classifier = TransactionClassifier()

    // MARK: - isDrinkRelated

    @Test("Identifies bar MCC as drink-related")
    func barMccIsDrinkRelated() {
        #expect(classifier.isDrinkRelated(merchantCategoryCode: "5813"))
    }

    @Test("Identifies liquor store MCC as drink-related")
    func liquorStoreMccIsDrinkRelated() {
        #expect(classifier.isDrinkRelated(merchantCategoryCode: "5921"))
    }

    @Test("Identifies restaurant MCC as drink-related")
    func restaurantMccIsDrinkRelated() {
        #expect(classifier.isDrinkRelated(merchantCategoryCode: "5812"))
    }

    @Test("Does not identify grocery store as drink-related")
    func groceryNotDrinkRelated() {
        #expect(!classifier.isDrinkRelated(merchantCategoryCode: "5411"))
    }

    @Test("Returns false for nil MCC")
    func nilMccNotDrinkRelated() {
        #expect(!classifier.isDrinkRelated(merchantCategoryCode: nil))
    }

    @Test("Returns false for empty string MCC")
    func emptyMccNotDrinkRelated() {
        #expect(!classifier.isDrinkRelated(merchantCategoryCode: ""))
    }

    // MARK: - classify

    @Test("Classifies bar transaction with high confidence")
    func classifyBarTransaction() {
        let transaction = TransactionDTO(
            id: "tx_1",
            amount: 45.00,
            currency: "USD",
            merchantName: "The Irish Pub",
            merchantCategory: "Bars/Taverns",
            merchantCategoryCode: "5813",
            merchantCity: "New York",
            merchantCountry: "US",
            timestamp: Date(),
            status: "completed"
        )

        let result = classifier.classify(transaction)
        #expect(result.isDrinkPurchase)
        #expect(result.confidence == .high)
        #expect(result.category == .barOrTavern)
    }

    @Test("Classifies liquor store with high confidence")
    func classifyLiquorStore() {
        let transaction = TransactionDTO(
            id: "tx_2",
            amount: 30.00,
            currency: "USD",
            merchantName: "ABC Liquor",
            merchantCategory: "Liquor Stores",
            merchantCategoryCode: "5921",
            merchantCity: nil,
            merchantCountry: nil,
            timestamp: Date(),
            status: "completed"
        )

        let result = classifier.classify(transaction)
        #expect(result.isDrinkPurchase)
        #expect(result.confidence == .high)
        #expect(result.category == .liquorStore)
    }

    @Test("Classifies restaurant with medium confidence, not drink purchase")
    func classifyRestaurant() {
        let transaction = TransactionDTO(
            id: "tx_3",
            amount: 65.00,
            currency: "USD",
            merchantName: "Olive Garden",
            merchantCategory: "Restaurants",
            merchantCategoryCode: "5812",
            merchantCity: nil,
            merchantCountry: nil,
            timestamp: Date(),
            status: "completed"
        )

        let result = classifier.classify(transaction)
        #expect(!result.isDrinkPurchase)
        #expect(result.confidence == .medium)
        #expect(result.category == .restaurant)
    }

    @Test("Classifies unknown MCC as non-drink with high confidence")
    func classifyUnknownMcc() {
        let transaction = TransactionDTO(
            id: "tx_4",
            amount: 100.00,
            currency: "USD",
            merchantName: "Best Buy",
            merchantCategory: "Electronics",
            merchantCategoryCode: "5732",
            merchantCity: nil,
            merchantCountry: nil,
            timestamp: Date(),
            status: "completed"
        )

        let result = classifier.classify(transaction)
        #expect(!result.isDrinkPurchase)
        #expect(result.confidence == .high)
        #expect(result.category == .other)
    }

    // MARK: - estimateDrinkCount

    @Test("Estimates single drink for small amounts")
    func estimateSingleDrink() {
        #expect(classifier.estimateDrinkCount(amount: 8.00) == 1)
    }

    @Test("Estimates multiple drinks proportionally")
    func estimateMultipleDrinks() {
        #expect(classifier.estimateDrinkCount(amount: 24.00) == 3)
    }

    @Test("Returns zero for zero amount")
    func estimateZeroAmount() {
        #expect(classifier.estimateDrinkCount(amount: 0) == 0)
    }

    @Test("Returns zero for negative amount")
    func estimateNegativeAmount() {
        #expect(classifier.estimateDrinkCount(amount: -10) == 0)
    }

    @Test("Uses custom average price")
    func estimateWithCustomPrice() {
        #expect(classifier.estimateDrinkCount(amount: 30, averageDrinkPrice: 10) == 3)
    }

    @Test("Returns at least 1 for any positive amount")
    func estimateMinimumOne() {
        #expect(classifier.estimateDrinkCount(amount: 2.00) == 1)
    }
}
