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
        self.displayName = displayName
        self.email = email
        self.appleUserIdentifier = appleUserIdentifier
        self.createdAt = Date()
        self.weightKg = weightKg
        self.biologicalSex = biologicalSex
        self.monthlyBudget = monthlyBudget
        self.weeklyDrinkGoal = weeklyDrinkGoal
        self.prefersDarkMode = false
        self.notificationsEnabled = true
        self.cardLinked = false
        self.cardLastFour = nil
    }
}

enum BiologicalSex: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    case preferNotToSay = "Prefer not to say"
}
