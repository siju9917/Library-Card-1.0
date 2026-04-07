import Foundation
import SwiftData

/// Manages showdown (team vs team) lifecycle.
@MainActor
final class ShowdownManager: ObservableObject {
    @Published var activeShowdown: Showdown?
    @Published var isShowdownActive: Bool = false

    func createShowdown(
        name: String,
        teamNames: [String],
        session: DrinkingSession?,
        in context: ModelContext
    ) -> Showdown {
        let showdown = Showdown(name: name, session: session)
        context.insert(showdown)

        for teamName in teamNames {
            let team = ShowdownTeam(name: teamName, showdown: showdown)
            context.insert(team)
            showdown.teams.append(team)
        }

        activeShowdown = showdown
        return showdown
    }

    func addParticipant(
        userId: UUID,
        displayName: String,
        to team: ShowdownTeam,
        in context: ModelContext
    ) {
        let participant = ShowdownParticipant(
            userId: userId,
            displayName: displayName,
            team: team
        )
        context.insert(participant)
        team.participants.append(participant)
    }

    func startShowdown(in context: ModelContext) {
        guard let showdown = activeShowdown, showdown.status == .setup else { return }
        showdown.start()

        do {
            try context.save()
        } catch {
            AppError.log(.persistence("Failed to start showdown: \(error.localizedDescription)"))
        }

        isShowdownActive = true
    }

    func logDrink(
        for participant: ShowdownParticipant,
        in context: ModelContext
    ) {
        participant.logDrink()

        do {
            try context.save()
        } catch {
            AppError.log(.persistence("Failed to log showdown drink: \(error.localizedDescription)"))
        }
    }

    func endShowdown(in context: ModelContext) {
        guard let showdown = activeShowdown else { return }
        showdown.end()

        do {
            try context.save()
        } catch {
            AppError.log(.persistence("Failed to end showdown: \(error.localizedDescription)"))
        }

        isShowdownActive = false
        activeShowdown = nil
    }
}
