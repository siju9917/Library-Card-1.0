import Foundation
import SwiftData

@Model
final class User {
    var id: UUID
    var displayName: String
    var email: String?
    var appleUserIdentifier: String?
    var createdAt: Date
    var weightKg: Double?
    var biologicalSex: BiologicalSex?
    var monthlyBudget: Double?
    var weeklyDrinkGoal: Int?
    var prefersDarkMode: Bool
    var notificationsEnabled: Bool
    var cardLinked: Bool
    var cardLastFour: String?

    @Relationship(deleteRule: .cascade, inverse: \DrinkingSession.user)
    var sessions: [DrinkingSession] = []

    init(
        displayName: String,
        email: String? = nil,
        appleUserIdentifier: String? = nil,
        weightKg: Double? = nil,
        biologicalSex: BiologicalSex? = nil,
        monthlyBudget: Double? = nil,
        weeklyDrinkGoal: Int? = nil
    ) {
        self.id = UUID()
        self.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "User" : displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email = email
        self.appleUserIdentifier = appleUserIdentifier
        self.createdAt = Date()
        self.weightKg = weightKg.flatMap { $0 > 0 && $0 < 500 ? $0 : nil }
        self.biologicalSex = biologicalSex
        self.monthlyBudget = monthlyBudget.flatMap { $0 >= 0 ? $0 : nil }
        self.weeklyDrinkGoal = weeklyDrinkGoal.flatMap { $0 >= 0 ? $0 : nil }
        self.prefersDarkMode = false
        self.notificationsEnabled = true
        self.cardLinked = false
        self.cardLastFour = nil
    }

    /// Validate and update weight safely.
    func updateWeight(_ kg: Double?) {
        if let kg = kg {
            guard kg > 0, kg < 500 else { return }
            weightKg = kg
        } else {
            weightKg = nil
        }
    }

    /// Validate and update budget safely.
    func updateBudget(_ budget: Double?) {
        if let budget = budget {
            guard budget >= 0 else { return }
            monthlyBudget = budget
        } else {
            monthlyBudget = nil
        }
    }

    /// Validate and update weekly goal safely.
    func updateWeeklyGoal(_ goal: Int?) {
        if let goal = goal {
            guard goal >= 0 else { return }
            weeklyDrinkGoal = goal
        } else {
            weeklyDrinkGoal = nil
        }
    }
}

enum BiologicalSex: String, Codable, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    case nonBinary = "Non-binary"
    case preferNotToSay = "Prefer not to say"

    var id: String { rawValue }
}
