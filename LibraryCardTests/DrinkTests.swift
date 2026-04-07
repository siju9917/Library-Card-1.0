import Testing
import Foundation
@testable import LibraryCard

@Suite("Drink Model Tests")
struct DrinkTests {

    // MARK: - Initialization

    @Test("Creates drink with valid parameters")
    func validDrinkCreation() throws {
        let drink = try Drink(
            type: .beer,
            name: "IPA",
            sizeMl: 355,
            alcoholPercentage: 6.5,
            price: 8.50
        )

        #expect(drink.type == .beer)
        #expect(drink.name == "IPA")
        #expect(drink.sizeMl == 355)
        #expect(drink.alcoholPercentage == 6.5)
        #expect(drink.price == 8.50)
        #expect(!drink.isAutoLogged)
        #expect(drink.id != UUID())
    }

    @Test("Trims whitespace from drink name")
    func trimsDrinkName() throws {
        let drink = try Drink(type: .beer, name: "  Lager  ", sizeMl: 355, alcoholPercentage: 5.0)
        #expect(drink.name == "Lager")
    }

    // MARK: - Validation

    @Test("Rejects empty name")
    func rejectsEmptyName() {
        #expect(throws: ValidationError.self) {
            try Drink(type: .beer, name: "", sizeMl: 355, alcoholPercentage: 5.0)
        }
    }

    @Test("Rejects whitespace-only name")
    func rejectsWhitespaceName() {
        #expect(throws: ValidationError.self) {
            try Drink(type: .beer, name: "   ", sizeMl: 355, alcoholPercentage: 5.0)
        }
    }

    @Test("Rejects zero size")
    func rejectsZeroSize() {
        #expect(throws: ValidationError.self) {
            try Drink(type: .beer, name: "Beer", sizeMl: 0, alcoholPercentage: 5.0)
        }
    }

    @Test("Rejects negative size")
    func rejectsNegativeSize() {
        #expect(throws: ValidationError.self) {
            try Drink(type: .beer, name: "Beer", sizeMl: -100, alcoholPercentage: 5.0)
        }
    }

    @Test("Rejects size over 5000ml")
    func rejectsExcessiveSize() {
        #expect(throws: ValidationError.self) {
            try Drink(type: .beer, name: "Beer", sizeMl: 5001, alcoholPercentage: 5.0)
        }
    }

    @Test("Rejects negative ABV")
    func rejectsNegativeAbv() {
        #expect(throws: ValidationError.self) {
            try Drink(type: .beer, name: "Beer", sizeMl: 355, alcoholPercentage: -1)
        }
    }

    @Test("Rejects ABV over 100")
    func rejectsExcessiveAbv() {
        #expect(throws: ValidationError.self) {
            try Drink(type: .beer, name: "Beer", sizeMl: 355, alcoholPercentage: 101)
        }
    }

    @Test("Accepts zero ABV (non-alcoholic)")
    func acceptsZeroAbv() throws {
        let drink = try Drink(type: .beer, name: "NA Beer", sizeMl: 355, alcoholPercentage: 0)
        #expect(drink.alcoholPercentage == 0)
    }

    @Test("Rejects negative price")
    func rejectsNegativePrice() {
        #expect(throws: ValidationError.self) {
            try Drink(type: .beer, name: "Beer", sizeMl: 355, alcoholPercentage: 5.0, price: -5)
        }
    }

    @Test("Accepts nil price")
    func acceptsNilPrice() throws {
        let drink = try Drink(type: .beer, name: "Beer", sizeMl: 355, alcoholPercentage: 5.0, price: nil)
        #expect(drink.price == nil)
    }

    // MARK: - Computed Properties

    @Test("Calculates standard units for a typical beer")
    func standardUnitsForBeer() throws {
        // 12oz (355ml) at 5% = ~1 standard drink
        let drink = try Drink(type: .beer, name: "Lager", sizeMl: 355, alcoholPercentage: 5.0)
        // 355 * 0.05 = 17.75ml alcohol * 0.789 = 14.0 grams / 14 = ~1.0 units
        #expect(drink.standardUnits > 0.9 && drink.standardUnits < 1.1)
    }

    @Test("Calculates standard units for a shot")
    func standardUnitsForShot() throws {
        // 1.5oz (44ml) at 40% = ~1 standard drink
        let drink = try Drink(type: .shot, name: "Vodka", sizeMl: 44, alcoholPercentage: 40.0)
        #expect(drink.standardUnits > 0.9 && drink.standardUnits < 1.1)
    }

    @Test("Calculates calories correctly")
    func calorieCalculation() {
        // 355ml at 5%: 17.75ml alcohol * 0.789g/ml = 14.0g * 7 cal/g = 98 cal
        let cals = Drink.calculateCalories(sizeMl: 355, alcoholPercentage: 5.0)
        #expect(cals > 90 && cals < 105)
    }

    @Test("Formats size correctly for ml")
    func sizeFormattingMl() throws {
        let drink = try Drink(type: .beer, name: "Beer", sizeMl: 355, alcoholPercentage: 5.0)
        #expect(drink.sizeFormatted == "355ml")
    }

    @Test("Formats size correctly for liters")
    func sizeFormattingLiters() throws {
        let drink = try Drink(type: .beer, name: "Pitcher", sizeMl: 1500, alcoholPercentage: 5.0)
        #expect(drink.sizeFormatted == "1.5L")
    }

    // MARK: - DrinkType

    @Test("All drink types have valid default sizes")
    func allTypesHaveValidDefaults() {
        for type in DrinkType.allCases {
            #expect(type.defaultSizeMl > 0)
            #expect(type.defaultAlcoholPercentage >= 0)
            #expect(!type.icon.isEmpty)
            #expect(!type.rawValue.isEmpty)
        }
    }
}
