import Foundation
import SwiftData

@Observable
final class ProfileViewModel {
    var user: User?
    var totalLifetimeDrinks: Int = 0
    var totalLifetimeSpend: Double = 0
    var totalSessions: Int = 0
    var memberSinceDays: Int = 0
    var favoriteVenue: String = "None yet"
    var favoriteDrinkType: String = "None yet"

    func loadProfile(user: User?, sessions: [DrinkingSession]) {
        self.user = user

        let completed = sessions.filter { $0.status == .completed }
        totalSessions = completed.count
        totalLifetimeDrinks = completed.reduce(0) { $0 + $1.totalDrinks }
        totalLifetimeSpend = completed.reduce(0) { $0 + $1.totalSpend }

        if let createdAt = user?.createdAt {
            memberSinceDays = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
        }

        // Favorite venue
        var venueCounts: [String: Int] = [:]
        for session in completed {
            let name = session.venue?.name ?? "Unknown"
            venueCounts[name, default: 0] += 1
        }
        if let top = venueCounts.max(by: { $0.value < $1.value }) {
            favoriteVenue = top.key
        }

        // Favorite drink type
        var typeCounts: [DrinkType: Int] = [:]
        for drink in completed.flatMap(\.drinks) {
            typeCounts[drink.type, default: 0] += 1
        }
        if let top = typeCounts.max(by: { $0.value < $1.value }) {
            favoriteDrinkType = top.key.rawValue
        }
    }
}
