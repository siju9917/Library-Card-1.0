import Testing
import Foundation
@testable import LibraryCard

@Suite("AppError Tests")
struct AppErrorTests {

    @Test("Validation error provides user message")
    func validationErrorMessage() {
        let error = AppError.validation("Invalid input")
        #expect(error.errorDescription == "Invalid input")
        #expect(error.userMessage == "Invalid input")
    }

    @Test("Persistence error provides generic user message")
    func persistenceErrorMessage() {
        let error = AppError.persistence("CoreData failure")
        #expect(error.errorDescription == "CoreData failure")
        #expect(error.userMessage == "Something went wrong saving your data. Please try again.")
    }

    @Test("Network error provides generic user message")
    func networkErrorMessage() {
        let error = AppError.network("timeout")
        #expect(error.userMessage == "Network error. Please check your connection.")
    }

    @Test("Card service error provides generic user message")
    func cardServiceErrorMessage() {
        let error = AppError.cardService("API down")
        #expect(error.userMessage == "Card service unavailable. Please try again later.")
    }

    @Test("Unknown error provides generic user message")
    func unknownErrorMessage() {
        let error = AppError.unknown("something broke")
        #expect(error.userMessage == "An unexpected error occurred.")
    }
}

@Suite("ValidationError Tests")
struct ValidationErrorTests {

    @Test("Invalid size error has description")
    func invalidSizeDescription() {
        let error = ValidationError.invalidSize("Size must be positive")
        #expect(error.errorDescription == "Size must be positive")
    }

    @Test("Empty name error has description")
    func emptyNameDescription() {
        let error = ValidationError.emptyName("Name required")
        #expect(error.errorDescription == "Name required")
    }

    @Test("Invalid coordinates error has description")
    func invalidCoordsDescription() {
        let error = ValidationError.invalidCoordinates("Out of range")
        #expect(error.errorDescription == "Out of range")
    }
}

@Suite("CardServiceError Tests")
struct CardServiceErrorTests {

    @Test("Not implemented error has description")
    func notImplementedDescription() {
        let error = CardServiceError.notImplemented
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("not yet configured"))
    }

    @Test("All error cases have descriptions")
    func allCasesHaveDescriptions() {
        let errors: [CardServiceError] = [
            .notImplemented,
            .networkError("timeout"),
            .authenticationRequired,
            .cardNotFound,
            .insufficientFunds
        ]
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}
