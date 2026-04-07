import Foundation
import SwiftData
import SwiftUI

@Observable
final class HomeViewModel {
    var recentSessions: [DrinkingSession] = []
    var totalDrinksThisWeek: Int = 0
    var totalDrinksAllTime: Int = 0
    var averageDrinksPerSession: Double = 0
    var currentStreak: Int = 0

    func loadData(sessions: [DrinkingSession]) {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        // Recent sessions (last 5, completed)
        recentSessions = sessions
            .filter { $0.status == .completed }
            .sorted { $0.startTime > $1.startTime }
            .prefix(5)
            .map { $0 }

        // This week's stats
        let thisWeekSessions = sessions.filter {
            $0.status == .completed && $0.startTime >= weekAgo
        }
        totalDrinksThisWeek = thisWeekSessions.reduce(0) { $0 + $1.totalDrinks }

        // Average drinks per session (all time)
        let completedSessions = sessions.filter { $0.status == .completed }
        totalDrinksAllTime = completedSessions.reduce(0) { $0 + $1.totalDrinks }
        if !completedSessions.isEmpty {
            averageDrinksPerSession = Double(totalDrinksAllTime) / Double(completedSessions.count)
        }

        // Dry day streak
        currentStreak = calculateDryDayStreak(sessions: sessions)
    }

    private func calculateDryDayStreak(sessions: [DrinkingSession]) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        // Check backwards from yesterday
        checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate

        let completedSessions = sessions.filter { $0.status == .completed }

        for _ in 0..<365 {
            let dayStart = checkDate
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

            let hasDrinks = completedSessions.contains { session in
                session.startTime >= dayStart && session.startTime < dayEnd && session.totalDrinks > 0
            }

            if hasDrinks {
                break
            }
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        return streak
    }
}
