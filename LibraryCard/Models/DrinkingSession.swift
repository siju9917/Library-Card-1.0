import Foundation
import SwiftData

@Model
final class DrinkingSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var status: SessionStatus
    var notes: String?

    var user: User?
    var venue: Venue?

    @Relationship(deleteRule: .cascade, inverse: \Drink.session)
    var drinks: [Drink] = []

    @Relationship(deleteRule: .cascade, inverse: \SessionPhoto.session)
    var photos: [SessionPhoto] = []

    @Relationship(deleteRule: .nullify, inverse: \Showdown.session)
    var showdown: Showdown?

    @Relationship(deleteRule: .cascade, inverse: \BarCheckIn.session)
    var barRoute: [BarCheckIn] = []

    init(
        user: User? = nil,
        venue: Venue? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.startTime = Date()
        self.endTime = nil
        self.status = .active
        self.notes = notes
        self.user = user
        self.venue = venue
    }

    // MARK: - Core Stats

    var isActive: Bool {
        status == .active
    }

    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    var durationFormatted: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var totalDrinks: Int {
        drinks.count
    }

    /// Drinks Per Minute — the signature metric
    var dpm: Double {
        let minutes = max(duration / 60, 0.1)
        return Double(totalDrinks) / minutes
    }

    /// Drinks Per Hour (display-friendly version of pace)
    var drinksPerHour: Double {
        let hours = max(duration / 3600, 0.01)
        return Double(totalDrinks) / hours
    }

    var drinkTypeBreakdown: [DrinkType: Int] {
        var breakdown: [DrinkType: Int] = [:]
        for drink in drinks {
            breakdown[drink.type, default: 0] += 1
        }
        return breakdown
    }

    /// Most consumed drink type this session
    var drinkOfChoice: DrinkType? {
        drinkTypeBreakdown.max(by: { $0.value < $1.value })?.key
    }

    var standardUnits: Double {
        drinks.reduce(0) { $0 + $1.standardUnits }
    }

    var totalCalories: Double {
        drinks.reduce(0) { $0 + $1.calories }
    }

    /// Number of photo posts earned this session (1 per drink)
    var photoPostsEarned: Int {
        totalDrinks
    }

    var photoPostsUsed: Int {
        photos.count
    }

    var photoPostsRemaining: Int {
        max(photoPostsEarned - photoPostsUsed, 0)
    }

    /// Ordered bar route for the night (chronological)
    var barRouteOrdered: [BarCheckIn] {
        barRoute.sorted { $0.orderIndex < $1.orderIndex }
    }

    /// Number of unique venues visited this session
    var venuesVisited: Int {
        barRoute.count
    }

    /// Current venue (latest check-in that hasn't departed)
    var currentVenue: BarCheckIn? {
        barRoute.first { $0.isCurrentlyHere }
    }

    // MARK: - BAC

    var estimatedBAC: Double? {
        guard let user = user,
              let weightKg = user.weightKg,
              let sex = user.biologicalSex,
              sex != .preferNotToSay else {
            return nil
        }
        let r: Double = (sex == .male) ? 0.68 : 0.55
        let gramsAlcohol = standardUnits * 14.0
        let hours = duration / 3600
        let bac = (gramsAlcohol / (weightKg * 1000 * r)) * 100 - (0.015 * hours)
        return max(bac, 0)
    }

    // MARK: - Live Distribution Data

    /// Cumulative drink count at each timestamp for charting pace over time
    var cumulativeDrinkTimeline: [(timestamp: Date, count: Int)] {
        let sorted = drinks.sorted { $0.timestamp < $1.timestamp }
        var timeline: [(timestamp: Date, count: Int)] = []
        timeline.append((timestamp: startTime, count: 0))
        for (index, drink) in sorted.enumerated() {
            timeline.append((timestamp: drink.timestamp, count: index + 1))
        }
        return timeline
    }

    // MARK: - Actions

    func end() {
        endTime = Date()
        status = .completed
    }
}

enum SessionStatus: String, Codable, CaseIterable {
    case active = "Active"
    case completed = "Completed"
    case cancelled = "Cancelled"
}
