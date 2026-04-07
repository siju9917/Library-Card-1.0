import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
final class SessionManager: ObservableObject {
    @Published var activeSession: DrinkingSession?
    @Published var isSessionActive: Bool = false
    @Published var elapsedTime: TimeInterval = 0

    private var timer: Timer?

    func startSession(user: User?, venue: Venue?, in context: ModelContext) {
        let session = DrinkingSession(user: user, venue: venue)
        context.insert(session)
        activeSession = session
        isSessionActive = true
        startTimer()

        if let venue = venue {
            venue.recordVisit(amount: 0)
        }
    }

    func endSession(in context: ModelContext) {
        guard let session = activeSession else { return }
        session.end()

        if let venue = session.venue {
            venue.totalSpent += session.totalSpend
        }

        try? context.save()
        stopTimer()
        activeSession = nil
        isSessionActive = false
        elapsedTime = 0
    }

    func cancelSession(in context: ModelContext) {
        guard let session = activeSession else { return }
        session.status = .cancelled
        session.endTime = Date()
        try? context.save()
        stopTimer()
        activeSession = nil
        isSessionActive = false
        elapsedTime = 0
    }

    func addDrink(
        type: DrinkType,
        name: String,
        sizeMl: Double,
        alcoholPercentage: Double,
        price: Double?,
        venue: Venue?,
        in context: ModelContext
    ) {
        guard let session = activeSession else { return }

        let drink = Drink(
            type: type,
            name: name,
            sizeMl: sizeMl,
            alcoholPercentage: alcoholPercentage,
            price: price,
            session: session,
            venue: venue
        )
        context.insert(drink)
        session.drinks.append(drink)
        try? context.save()
    }

    // MARK: - Timer

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
