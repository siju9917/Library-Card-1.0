import Foundation
import SwiftData

/// Spotify-style recap of drinking stats for a time period.
/// Generated at the end of each week, month, and year.
@Model
final class Wrapped {
    var id: UUID
    var userId: UUID
    var period: WrappedPeriod
    var periodStart: Date
    var periodEnd: Date
    var generatedAt: Date

    // Core stats
    var totalDrinks: Int
    var totalSessions: Int
    var totalMinutesOut: Double
    var averageDPM: Double
    var peakDPM: Double
    var peakDPMSessionDate: Date?

    // Drink of choice
    var topDrinkType: String  // DrinkType raw value
    var topDrinkTypeCount: Int

    // Social
    var topVenueName: String?
    var topVenueVisits: Int
    var uniqueVenuesVisited: Int

    // Fun stats
    var totalCalories: Double
    var totalStandardUnits: Double
    var longestSessionMinutes: Double
    var busiestDayOfWeek: String  // "Friday", "Saturday", etc.
    var busiestDayDrinks: Int

    // Rankings (within friends / org)
    var friendsRankDPM: Int?       // e.g., "#3 among friends"
    var friendsTotalCompared: Int?
    var orgRank: Int?
    var orgName: String?

    init(
        userId: UUID,
        period: WrappedPeriod,
        periodStart: Date,
        periodEnd: Date
    ) {
        self.id = UUID()
        self.userId = userId
        self.period = period
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.generatedAt = Date()

        // Defaults — will be computed by WrappedGenerator
        self.totalDrinks = 0
        self.totalSessions = 0
        self.totalMinutesOut = 0
        self.averageDPM = 0
        self.peakDPM = 0
        self.peakDPMSessionDate = nil
        self.topDrinkType = DrinkType.beer.rawValue
        self.topDrinkTypeCount = 0
        self.topVenueName = nil
        self.topVenueVisits = 0
        self.uniqueVenuesVisited = 0
        self.totalCalories = 0
        self.totalStandardUnits = 0
        self.longestSessionMinutes = 0
        self.busiestDayOfWeek = "Friday"
        self.busiestDayDrinks = 0
        self.friendsRankDPM = nil
        self.friendsTotalCompared = nil
        self.orgRank = nil
        self.orgName = nil
    }
}

enum WrappedPeriod: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var displayName: String {
        switch self {
        case .weekly: return "Week in Review"
        case .monthly: return "Monthly Wrapped"
        case .yearly: return "Year Wrapped"
        }
    }

    var icon: String {
        switch self {
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .yearly: return "star.circle.fill"
        }
    }
}
