import Testing
import Foundation
@testable import LibraryCard

@Suite("User Model Tests")
struct UserTests {

    @Test("Creates user with valid display name")
    func validUserCreation() {
        let user = User(displayName: "John Doe")
        #expect(user.displayName == "John Doe")
        #expect(user.notificationsEnabled == true)
        #expect(user.sessions.isEmpty)
        #expect(user.totalLifetimeDrinks == 0)
    }

    @Test("Defaults to 'User' for empty display name")
    func emptyDisplayNameDefaults() {
        let user = User(displayName: "")
        #expect(user.displayName == "User")
    }

    @Test("Defaults to 'User' for whitespace-only name")
    func whitespaceDisplayNameDefaults() {
        let user = User(displayName: "   ")
        #expect(user.displayName == "User")
    }

    @Test("Generates default username")
    func generatesUsername() {
        let user = User(displayName: "Jane")
        #expect(user.username.hasPrefix("user_"))
    }

    @Test("Rejects invalid weight in constructor")
    func rejectsInvalidWeight() {
        let user = User(displayName: "Jane", weightKg: -10)
        #expect(user.weightKg == nil)
    }

    @Test("Rejects zero weight")
    func rejectsZeroWeight() {
        let user = User(displayName: "Jane", weightKg: 0)
        #expect(user.weightKg == nil)
    }

    @Test("Rejects excessive weight")
    func rejectsExcessiveWeight() {
        let user = User(displayName: "Jane", weightKg: 600)
        #expect(user.weightKg == nil)
    }

    @Test("Accepts valid weight")
    func acceptsValidWeight() {
        let user = User(displayName: "Jane", weightKg: 70)
        #expect(user.weightKg == 70)
    }

    @Test("Rejects negative weekly goal")
    func rejectsNegativeGoal() {
        let user = User(displayName: "Jane", weeklyDrinkGoal: -5)
        #expect(user.weeklyDrinkGoal == nil)
    }

    // MARK: - Update Methods

    @Test("updateWeight validates input")
    func updateWeightValidation() {
        let user = User(displayName: "Jane")

        user.updateWeight(70)
        #expect(user.weightKg == 70)

        user.updateWeight(-10)
        #expect(user.weightKg == 70)

        user.updateWeight(nil)
        #expect(user.weightKg == nil)
    }

    @Test("updateWeeklyGoal validates input")
    func updateGoalValidation() {
        let user = User(displayName: "Jane")

        user.updateWeeklyGoal(14)
        #expect(user.weeklyDrinkGoal == 14)

        user.updateWeeklyGoal(-3)
        #expect(user.weeklyDrinkGoal == 14)

        user.updateWeeklyGoal(nil)
        #expect(user.weeklyDrinkGoal == nil)
    }

    @Test("Increment lifetime drinks")
    func incrementLifetimeDrinks() {
        let user = User(displayName: "Jane")
        #expect(user.totalLifetimeDrinks == 0)
        user.incrementLifetimeDrinks()
        #expect(user.totalLifetimeDrinks == 1)
        user.incrementLifetimeDrinks()
        #expect(user.totalLifetimeDrinks == 2)
    }

    // MARK: - BiologicalSex Enum

    @Test("BiologicalSex has expected cases")
    func biologicalSexCases() {
        let allCases = BiologicalSex.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.male))
        #expect(allCases.contains(.female))
        #expect(allCases.contains(.nonBinary))
        #expect(allCases.contains(.preferNotToSay))
    }
}
