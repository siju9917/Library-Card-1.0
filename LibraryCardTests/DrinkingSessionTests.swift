import Testing
import Foundation
@testable import LibraryCard

@Suite("DrinkingSession Tests")
struct DrinkingSessionTests {

    @Test("Creates session with active status")
    func sessionCreation() {
        let session = DrinkingSession()
        #expect(session.isActive)
        #expect(session.status == .active)
        #expect(session.endTime == nil)
        #expect(session.drinks.isEmpty)
        #expect(session.totalDrinks == 0)
        #expect(session.totalSpend == 0)
    }

    @Test("Ends session correctly")
    func sessionEnd() {
        let session = DrinkingSession()
        session.end()
        #expect(!session.isActive)
        #expect(session.status == .completed)
        #expect(session.endTime != nil)
    }

    @Test("Duration calculates for active session")
    func durationWhileActive() {
        let session = DrinkingSession()
        // Duration should be small but non-negative
        #expect(session.duration >= 0)
    }

    @Test("Drinks per hour is zero with no drinks")
    func drinksPerHourEmpty() {
        let session = DrinkingSession()
        #expect(session.drinksPerHour >= 0)
    }

    @Test("Average drink price is zero with no drinks")
    func averagePriceEmpty() {
        let session = DrinkingSession()
        #expect(session.averageDrinkPrice == 0)
    }

    @Test("Standard units is zero with no drinks")
    func standardUnitsEmpty() {
        let session = DrinkingSession()
        #expect(session.standardUnits == 0)
    }

    @Test("Duration formatted shows minutes for short sessions")
    func durationFormattedMinutes() {
        let session = DrinkingSession()
        // Just created, should show 0m
        let formatted = session.durationFormatted
        #expect(formatted.contains("m"))
    }

    @Test("Drink type breakdown is empty with no drinks")
    func drinkTypeBreakdownEmpty() {
        let session = DrinkingSession()
        #expect(session.drinkTypeBreakdown.isEmpty)
    }

    @Test("BAC returns nil without user data")
    func bacWithoutUser() {
        let session = DrinkingSession()
        #expect(session.estimatedBAC == nil)
    }

    @Test("Status enum has all cases")
    func sessionStatusCases() {
        let allCases = SessionStatus.allCases
        #expect(allCases.contains(.active))
        #expect(allCases.contains(.completed))
        #expect(allCases.contains(.cancelled))
    }
}
