import Foundation
import SwiftData

@Model
final class Showdown {
    var id: UUID
    var name: String
    var createdAt: Date
    var startTime: Date?
    var endTime: Date?
    var status: ShowdownStatus

    var session: DrinkingSession?

    @Relationship(deleteRule: .cascade, inverse: \ShowdownTeam.showdown)
    var teams: [ShowdownTeam] = []

    init(
        name: String,
        session: DrinkingSession? = nil
    ) {
        self.id = UUID()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = Date()
        self.startTime = nil
        self.endTime = nil
        self.status = .setup
        self.session = session
    }

    // MARK: - Lifecycle

    func start() {
        startTime = Date()
        status = .active
    }

    func end() {
        endTime = Date()
        status = .completed
    }

    // MARK: - Stats

    var duration: TimeInterval {
        guard let start = startTime else { return 0 }
        let end = endTime ?? Date()
        return end.timeIntervalSince(start)
    }

    var isActive: Bool {
        status == .active
    }

    var winningTeam: ShowdownTeam? {
        guard status == .completed || status == .active else { return nil }
        return teams.max(by: { $0.totalDrinks < $1.totalDrinks })
    }

    var scoreboard: [(team: ShowdownTeam, drinks: Int, dpm: Double)] {
        let minutes = max(duration / 60, 0.1)
        return teams
            .map { team in
                let drinks = team.totalDrinks
                let dpm = Double(drinks) / minutes
                return (team: team, drinks: drinks, dpm: dpm)
            }
            .sorted { $0.drinks > $1.drinks }
    }
}

enum ShowdownStatus: String, Codable, CaseIterable {
    case setup = "Setting Up"
    case active = "Live"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

@Model
final class ShowdownTeam {
    var id: UUID
    var name: String
    var showdown: Showdown?

    @Relationship(deleteRule: .cascade, inverse: \ShowdownParticipant.team)
    var participants: [ShowdownParticipant] = []

    init(name: String, showdown: Showdown? = nil) {
        self.id = UUID()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.showdown = showdown
    }

    var totalDrinks: Int {
        participants.reduce(0) { $0 + $1.drinkCount }
    }

    var memberCount: Int {
        participants.count
    }

    /// Average DPM across team members
    var teamDPM: Double {
        guard let showdown = showdown, showdown.duration > 0 else { return 0 }
        let minutes = showdown.duration / 60
        return Double(totalDrinks) / max(minutes, 0.1)
    }
}

@Model
final class ShowdownParticipant {
    var id: UUID
    var userId: UUID
    var displayName: String
    var team: ShowdownTeam?
    var drinkCount: Int

    init(
        userId: UUID,
        displayName: String,
        team: ShowdownTeam? = nil
    ) {
        self.id = UUID()
        self.userId = userId
        self.displayName = displayName
        self.team = team
        self.drinkCount = 0
    }

    func logDrink() {
        drinkCount += 1
    }
}
