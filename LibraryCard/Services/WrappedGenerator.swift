import Foundation
import SwiftData

/// Generates Wrapped recaps from session data for a given time period.
struct WrappedGenerator {

    /// Generate a Wrapped for the given user and period.
    static func generate(
        userId: UUID,
        sessions: [DrinkingSession],
        period: WrappedPeriod,
        periodStart: Date,
        periodEnd: Date
    ) -> Wrapped {
        let wrapped = Wrapped(
            userId: userId,
            period: period,
            periodStart: periodStart,
            periodEnd: periodEnd
        )

        let completed = sessions.filter {
            $0.status == .completed &&
            $0.startTime >= periodStart &&
            $0.startTime < periodEnd
        }

        guard !completed.isEmpty else { return wrapped }

        // Core stats
        wrapped.totalSessions = completed.count
        wrapped.totalDrinks = completed.reduce(0) { $0 + $1.totalDrinks }
        wrapped.totalMinutesOut = completed.reduce(0) { $0 + $1.duration / 60 }

        let totalMinutes = max(wrapped.totalMinutesOut, 0.1)
        wrapped.averageDPM = Double(wrapped.totalDrinks) / totalMinutes

        // Peak DPM session
        if let peakSession = completed.max(by: { $0.dpm < $1.dpm }) {
            wrapped.peakDPM = peakSession.dpm
            wrapped.peakDPMSessionDate = peakSession.startTime
        }

        // Drink of choice
        var typeCounts: [DrinkType: Int] = [:]
        for drink in completed.flatMap(\.drinks) {
            typeCounts[drink.type, default: 0] += 1
        }
        if let top = typeCounts.max(by: { $0.value < $1.value }) {
            wrapped.topDrinkType = top.key.rawValue
            wrapped.topDrinkTypeCount = top.value
        }

        // Top venue
        var venueCounts: [String: Int] = [:]
        for session in completed {
            let name = session.venue?.name ?? "Unknown"
            venueCounts[name, default: 0] += 1
        }
        if let topVenue = venueCounts.max(by: { $0.value < $1.value }) {
            wrapped.topVenueName = topVenue.key
            wrapped.topVenueVisits = topVenue.value
        }
        wrapped.uniqueVenuesVisited = Set(completed.compactMap { $0.venue?.name }).count

        // Calories and units
        let allDrinks = completed.flatMap(\.drinks)
        wrapped.totalCalories = allDrinks.reduce(0) { $0 + $1.calories }
        wrapped.totalStandardUnits = allDrinks.reduce(0) { $0 + $1.standardUnits }

        // Longest session
        if let longest = completed.max(by: { $0.duration < $1.duration }) {
            wrapped.longestSessionMinutes = longest.duration / 60
        }

        // Busiest day of week
        let calendar = Calendar.current
        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var dayDrinks: [Int: Int] = [:]
        for session in completed {
            let weekday = calendar.component(.weekday, from: session.startTime)
            dayDrinks[weekday, default: 0] += session.totalDrinks
        }
        if let busiest = dayDrinks.max(by: { $0.value < $1.value }) {
            wrapped.busiestDayOfWeek = dayNames[busiest.key]
            wrapped.busiestDayDrinks = busiest.value
        }

        return wrapped
    }

    /// Get the date range for a given period ending now.
    static func periodRange(for period: WrappedPeriod, endingAt: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let end = endingAt

        switch period {
        case .weekly:
            let start = calendar.date(byAdding: .day, value: -7, to: end) ?? end
            return (start, end)
        case .monthly:
            let start = calendar.date(byAdding: .month, value: -1, to: end) ?? end
            return (start, end)
        case .yearly:
            let start = calendar.date(byAdding: .year, value: -1, to: end) ?? end
            return (start, end)
        }
    }
}
