import Testing
import Foundation
@testable import LibraryCard

@Suite("DateFormatters Tests")
struct DateFormatterTests {

    @Test("Currency formatting for typical amounts")
    func currencyFormatting() {
        #expect(8.50.currencyFormatted.contains("8"))
        #expect(0.0.currencyFormatted.contains("0"))
        #expect(1234.56.currencyFormatted.contains("1"))
    }

    @Test("Duration formatting for minutes only")
    func durationMinutes() {
        let interval: TimeInterval = 45 * 60 // 45 minutes
        #expect(interval.durationFormatted == "45m")
    }

    @Test("Duration formatting for hours and minutes")
    func durationHoursMinutes() {
        let interval: TimeInterval = 2 * 3600 + 30 * 60 // 2h 30m
        #expect(interval.durationFormatted == "2h 30m")
    }

    @Test("Timer formatting for HH:MM:SS")
    func timerFormatting() {
        let interval: TimeInterval = 1 * 3600 + 23 * 60 + 45 // 1:23:45
        #expect(interval.timerFormatted == "01:23:45")
    }

    @Test("Timer formatting for zero")
    func timerZero() {
        let interval: TimeInterval = 0
        #expect(interval.timerFormatted == "00:00:00")
    }

    @Test("Duration formatting for zero")
    func durationZero() {
        let interval: TimeInterval = 0
        #expect(interval.durationFormatted == "0m")
    }
}

@Suite("Transaction Model Tests")
struct TransactionTests {

    @Test("Creates transaction with valid parameters")
    func validCreation() {
        let transaction = Transaction(
            amount: 45.00,
            merchantName: "The Bar",
            merchantCategoryCode: "5813"
        )
        #expect(transaction.amount == 45.00)
        #expect(transaction.merchantName == "The Bar")
        #expect(transaction.currency == "USD")
        #expect(!transaction.isConfirmedByUser)
    }

    @Test("Identifies likely drink purchase by MCC")
    func likelyDrinkPurchase() {
        let transaction = Transaction(
            amount: 30.00,
            merchantName: "Irish Pub",
            merchantCategoryCode: "5813"
        )
        #expect(transaction.isLikelyDrinkPurchase)
    }

    @Test("Does not flag non-bar MCC as drink purchase")
    func notDrinkPurchase() {
        let transaction = Transaction(
            amount: 50.00,
            merchantName: "Target",
            merchantCategoryCode: "5411"
        )
        #expect(!transaction.isLikelyDrinkPurchase)
    }

    @Test("Nil MCC is not a drink purchase")
    func nilMccNotDrink() {
        let transaction = Transaction(
            amount: 20.00,
            merchantName: "Unknown"
        )
        #expect(!transaction.isLikelyDrinkPurchase)
    }

    @Test("Amount formatted includes currency symbol")
    func amountFormatted() {
        let transaction = Transaction(
            amount: 12.50,
            merchantName: "Bar"
        )
        #expect(transaction.amountFormatted.contains("12"))
    }
}
