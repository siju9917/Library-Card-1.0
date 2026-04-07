import Foundation
import SwiftData

@Observable
final class StatsViewModel {
    // Time period filter
    var selectedPeriod: StatsPeriod = .week

    // Computed stats
    var totalDrinks: Int = 0
    var totalSessions: Int = 0
    var averageDrinksPerSession: Double = 0
    var averageDrinksPerHour: Double = 0
    var averageDPM: Double = 0
    var totalCalories: Double = 0

    // Chart data
    var drinksOverTime: [DateDataPoint] = []
    var dpmOverTime: [DateDataPoint] = []
    var drinkTypeDistribution: [DrinkTypeDataPoint] = []
    var dayOfWeekDistribution: [DayOfWeekDataPoint] = []
    var topVenues: [VenueDataPoint] = []

    // Top drink type
    var topDrinkType: DrinkType? {
        drinkTypeDistribution.first?.type
    }

    func loadStats(sessions: [DrinkingSession]) {
        let filtered = filteredSessions(from: sessions)

        totalSessions = filtered.count
        totalDrinks = filtered.reduce(0) { $0 + $1.totalDrinks }

        if totalSessions > 0 {
            averageDrinksPerSession = Double(totalDrinks) / Double(totalSessions)
            averageDPM = filtered.reduce(0.0) { $0 + $1.dpm } / Double(totalSessions)
        }

        let totalHours = filtered.reduce(0.0) { $0 + $1.duration / 3600 }
        averageDrinksPerHour = totalHours > 0 ? Double(totalDrinks) / totalHours : 0

        totalCalories = filtered.flatMap(\.drinks).reduce(0) { $0 + $1.calories }

        buildDrinksOverTimeChart(filtered)
        buildDPMOverTimeChart(filtered)
        buildDrinkTypeChart(filtered)
        buildDayOfWeekChart(filtered)
        buildTopVenuesChart(filtered)
    }

    private func filteredSessions(from sessions: [DrinkingSession]) -> [DrinkingSession] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date

        switch selectedPeriod {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .allTime:
            startDate = .distantPast
        }

        return sessions.filter {
            $0.status == .completed && $0.startTime >= startDate
        }
    }

    private func buildDrinksOverTimeChart(_ sessions: [DrinkingSession]) {
        let calendar = Calendar.current
        var dataByDate: [Date: Int] = [:]

        for session in sessions {
            let day = calendar.startOfDay(for: session.startTime)
            dataByDate[day, default: 0] += session.totalDrinks
        }

        drinksOverTime = dataByDate
            .map { DateDataPoint(date: $0.key, value: Double($0.value)) }
            .sorted { $0.date < $1.date }
    }

    private func buildDPMOverTimeChart(_ sessions: [DrinkingSession]) {
        let calendar = Calendar.current
        var dataByDate: [Date: (totalDPM: Double, count: Int)] = [:]

        for session in sessions {
            let day = calendar.startOfDay(for: session.startTime)
            dataByDate[day, default: (0, 0)].totalDPM += session.dpm
            dataByDate[day, default: (0, 0)].count += 1
        }

        dpmOverTime = dataByDate
            .map { DateDataPoint(date: $0.key, value: $0.value.count > 0 ? $0.value.totalDPM / Double($0.value.count) : 0) }
            .sorted { $0.date < $1.date }
    }

    private func buildDrinkTypeChart(_ sessions: [DrinkingSession]) {
        var typeCounts: [DrinkType: Int] = [:]
        for drink in sessions.flatMap(\.drinks) {
            typeCounts[drink.type, default: 0] += 1
        }

        drinkTypeDistribution = typeCounts
            .map { DrinkTypeDataPoint(type: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private func buildDayOfWeekChart(_ sessions: [DrinkingSession]) {
        let calendar = Calendar.current
        var dayCounts: [Int: Int] = [:]

        for session in sessions {
            let weekday = calendar.component(.weekday, from: session.startTime)
            dayCounts[weekday, default: 0] += session.totalDrinks
        }

        let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        dayOfWeekDistribution = (1...7).map { day in
            DayOfWeekDataPoint(
                day: dayNames[day],
                dayNumber: day,
                count: dayCounts[day, default: 0]
            )
        }
    }

    private func buildTopVenuesChart(_ sessions: [DrinkingSession]) {
        var venueData: [String: Int] = [:]
        for session in sessions {
            let name = session.venue?.name ?? "Unknown"
            venueData[name, default: 0] += 1
        }

        topVenues = venueData
            .map { VenueDataPoint(name: $0.key, visits: $0.value) }
            .sorted { $0.visits > $1.visits }
            .prefix(5)
            .map { $0 }
    }
}

// MARK: - Data Types

enum StatsPeriod: String, CaseIterable {
    case week = "7D"
    case month = "1M"
    case threeMonths = "3M"
    case year = "1Y"
    case allTime = "All"
}

struct DateDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct DrinkTypeDataPoint: Identifiable {
    let id = UUID()
    let type: DrinkType
    let count: Int
}

struct DayOfWeekDataPoint: Identifiable {
    let id = UUID()
    let day: String
    let dayNumber: Int
    let count: Int
}

struct VenueDataPoint: Identifiable {
    let id = UUID()
    let name: String
    let visits: Int
}
