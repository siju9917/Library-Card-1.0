import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
final class SessionManager: ObservableObject, SessionManaging {
    @Published var activeSession: DrinkingSession?
    @Published var isSessionActive: Bool = false
    @Published var elapsedTime: TimeInterval = 0

    private let haptics: HapticService
    private let notifications: NotificationManaging
    private var timer: Timer?

    init(
        haptics: HapticService = .shared,
        notifications: NotificationManaging = NotificationService.shared
    ) {
        self.haptics = haptics
        self.notifications = notifications
    }

    func startSession(user: User?, venue: Venue?, in context: ModelContext) {
        guard !isSessionActive else { return }

        let session = DrinkingSession(user: user, venue: venue)
        context.insert(session)
        activeSession = session
        isSessionActive = true
        startTimer()
        haptics.sessionStart()
        notifications.scheduleInactivityReminder(afterMinutes: 60)

        venue?.recordVisit()

        do {
            try context.save()
        } catch {
            AppError.log(.persistence("Failed to save new session: \(error.localizedDescription)"))
        }
    }

    func endSession(in context: ModelContext) {
        guard let session = activeSession, session.isActive else { return }
        session.end()

        // Update user lifetime stats
        if let user = session.user {
            user.totalLifetimeDrinks += session.totalDrinks
        }

        do {
            try context.save()
        } catch {
            AppError.log(.persistence("Failed to save ended session: \(error.localizedDescription)"))
        }

        // Schedule funny morning-after notification
        FunNotificationService.shared.scheduleMorningAfter(
            totalDrinks: session.totalDrinks,
            sessionEndTime: Date()
        )

        cleanup()
        haptics.sessionEnd()
    }

    func cancelSession(in context: ModelContext) {
        guard let session = activeSession else { return }
        session.status = .cancelled
        session.endTime = Date()

        do {
            try context.save()
        } catch {
            AppError.log(.persistence("Failed to save cancelled session: \(error.localizedDescription)"))
        }

        cleanup()
    }

    func addDrink(
        type: DrinkType,
        name: String,
        sizeMl: Double,
        alcoholPercentage: Double,
        venue: Venue?,
        in context: ModelContext
    ) {
        guard let session = activeSession else { return }

        do {
            let drink = try Drink(
                type: type,
                name: name,
                sizeMl: sizeMl,
                alcoholPercentage: alcoholPercentage,
                session: session,
                venue: venue
            )
            context.insert(drink)
            session.drinks.append(drink)
            try context.save()
            haptics.drinkAdded()

            notifications.cancelInactivityReminder()
            notifications.scheduleInactivityReminder(afterMinutes: 60)
        } catch let error as ValidationError {
            AppError.log(.validation(error.localizedDescription))
        } catch {
            AppError.log(.persistence("Failed to save drink: \(error.localizedDescription)"))
        }
    }

    // MARK: - Private

    private func cleanup() {
        stopTimer()
        notifications.cancelInactivityReminder()
        activeSession = nil
        isSessionActive = false
        elapsedTime = 0
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let session = self.activeSession else { return }
                self.elapsedTime = Date().timeIntervalSince(session.startTime)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
