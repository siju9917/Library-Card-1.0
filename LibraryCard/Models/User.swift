import Foundation
import SwiftData

@Model
final class User {
    var id: UUID
    var displayName: String
    var username: String
    var email: String?
    var appleUserIdentifier: String?
    var createdAt: Date
    var weightKg: Double?
    var biologicalSex: BiologicalSex?
    var weeklyDrinkGoal: Int?
    var prefersDarkMode: Bool
    var notificationsEnabled: Bool
    var profileImageData: Data?

    // Social
    var bio: String?
    var totalLifetimeDrinks: Int
    var longestStreak: Int

    @Relationship(deleteRule: .cascade, inverse: \DrinkingSession.user)
    var sessions: [DrinkingSession] = []

    @Relationship(deleteRule: .nullify, inverse: \Friendship.user)
    var friendships: [Friendship] = []

    @Relationship(deleteRule: .nullify, inverse: \OrganizationMember.user)
    var memberships: [OrganizationMember] = []

    @Relationship(deleteRule: .cascade, inverse: \SessionPhoto.user)
    var photos: [SessionPhoto] = []

    init(
        displayName: String,
        username: String? = nil,
        email: String? = nil,
        appleUserIdentifier: String? = nil,
        weightKg: Double? = nil,
        biologicalSex: BiologicalSex? = nil,
        weeklyDrinkGoal: Int? = nil
    ) {
        self.id = UUID()
        self.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "User" : displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.username = username ?? "user_\(UUID().uuidString.prefix(8).lowercased())"
        self.email = email
        self.appleUserIdentifier = appleUserIdentifier
        self.createdAt = Date()
        self.weightKg = weightKg.flatMap { $0 > 0 && $0 < 500 ? $0 : nil }
        self.biologicalSex = biologicalSex
        self.weeklyDrinkGoal = weeklyDrinkGoal.flatMap { $0 >= 0 ? $0 : nil }
        self.prefersDarkMode = false
        self.notificationsEnabled = true
        self.profileImageData = nil
        self.bio = nil
        self.totalLifetimeDrinks = 0
        self.longestStreak = 0
    }

    func updateWeight(_ kg: Double?) {
        if let kg = kg {
            guard kg > 0, kg < 500 else { return }
            weightKg = kg
        } else {
            weightKg = nil
        }
    }

    func updateWeeklyGoal(_ goal: Int?) {
        if let goal = goal {
            guard goal >= 0 else { return }
            weeklyDrinkGoal = goal
        } else {
            weeklyDrinkGoal = nil
        }
    }

    func incrementLifetimeDrinks() {
        totalLifetimeDrinks += 1
    }
}

enum BiologicalSex: String, Codable, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    case nonBinary = "Non-binary"
    case preferNotToSay = "Prefer not to say"

    var id: String { rawValue }
}
