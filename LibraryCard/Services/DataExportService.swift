import Foundation
import SwiftData

/// Handles data export (GDPR/CCPA compliance) and account deletion.
struct DataExportService {

    /// Export all user data as a JSON string.
    static func exportAll(context: ModelContext) -> String {
        var export: [String: Any] = [:]

        // Users
        if let users = try? context.fetch(FetchDescriptor<User>()),
           let user = users.first {
            export["profile"] = [
                "displayName": user.displayName,
                "username": user.username,
                "email": user.email ?? "N/A",
                "createdAt": ISO8601DateFormatter().string(from: user.createdAt),
                "totalLifetimeDrinks": user.totalLifetimeDrinks,
                "longestStreak": user.longestStreak
            ]
        }

        // Sessions
        if let sessions = try? context.fetch(FetchDescriptor<DrinkingSession>()) {
            export["sessions"] = sessions.map { session in
                [
                    "id": session.id.uuidString,
                    "startTime": ISO8601DateFormatter().string(from: session.startTime),
                    "endTime": session.endTime.map { ISO8601DateFormatter().string(from: $0) } ?? "N/A",
                    "status": session.status.rawValue,
                    "totalDrinks": session.totalDrinks,
                    "dpm": String(format: "%.4f", session.dpm),
                    "drinksPerHour": String(format: "%.2f", session.drinksPerHour),
                    "venue": session.venue?.name ?? "N/A",
                    "drinks": session.drinks.map { drink in
                        [
                            "type": drink.type.rawValue,
                            "name": drink.name,
                            "sizeMl": drink.sizeMl,
                            "abv": drink.alcoholPercentage,
                            "timestamp": ISO8601DateFormatter().string(from: drink.timestamp),
                            "calories": drink.calories
                        ] as [String: Any]
                    }
                ] as [String: Any]
            }
        }

        // Venues
        if let venues = try? context.fetch(FetchDescriptor<Venue>()) {
            export["venues"] = venues.map { venue in
                [
                    "name": venue.name,
                    "category": venue.category.rawValue,
                    "visitCount": venue.visitCount
                ] as [String: Any]
            }
        }

        // Convert to JSON
        if let jsonData = try? JSONSerialization.data(withJSONObject: export, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }

        return "{\"error\": \"Failed to export data\"}"
    }

    /// Delete ALL user data from the database.
    static func deleteAllData(context: ModelContext) {
        do {
            try context.delete(model: SessionPhoto.self)
            try context.delete(model: BarCheckIn.self)
            try context.delete(model: Drink.self)
            try context.delete(model: DrinkingSession.self)
            try context.delete(model: Venue.self)
            try context.delete(model: Friendship.self)
            try context.delete(model: OrganizationMember.self)
            try context.delete(model: Organization.self)
            try context.delete(model: ShowdownParticipant.self)
            try context.delete(model: ShowdownTeam.self)
            try context.delete(model: Showdown.self)
            try context.delete(model: Wrapped.self)
            try context.delete(model: DirectMessage.self)
            try context.delete(model: Conversation.self)
            try context.delete(model: SwipeAction.self)
            try context.delete(model: Match.self)
            try context.delete(model: PreSwipe.self)
            try context.delete(model: DrinkGift.self)
            try context.delete(model: SOSAlert.self)
            try context.delete(model: DepartureNotification.self)
            try context.delete(model: PremiumSubscription.self)
            try context.delete(model: IDVerification.self)
            try context.delete(model: User.self)
            try context.save()
        } catch {
            AppError.log(.persistence("Failed to delete all data: \(error.localizedDescription)"))
        }
    }
}
