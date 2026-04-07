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

    @Relationship(deleteRule: .nullify, inverse: \Transaction.session)
    var transactions: [Transaction] = []

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

    // MARK: - Computed Properties

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

    var totalSpend: Double {
        drinks.reduce(0) { $0 + ($1.price ?? 0) }
    }

    var drinksPerHour: Double {
        let hours = max(duration / 3600, 0.01)
        return Double(totalDrinks) / hours
    }

    var averageDrinkPrice: Double {
        guard totalDrinks > 0 else { return 0 }
        return totalSpend / Double(totalDrinks)
    }

    var drinkTypeBreakdown: [DrinkType: Int] {
        var breakdown: [DrinkType: Int] = [:]
        for drink in drinks {
            breakdown[drink.type, default: 0] += 1
        }
        return breakdown
    }

    var standardUnits: Double {
        drinks.reduce(0) { $0 + $1.standardUnits }
    }

    var estimatedBAC: Double? {
        guard let user = user,
              let weightKg = user.weightKg,
              let sex = user.biologicalSex,
              sex != .preferNotToSay else {
            return nil
        }
        let r: Double = (sex == .male) ? 0.68 : 0.55
        let gramsAlcohol = standardUnits * 14.0 // 1 US standard drink = 14g alcohol
        let hours = duration / 3600
        let bac = (gramsAlcohol / (weightKg * 1000 * r)) * 100 - (0.015 * hours)
        return max(bac, 0)
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
