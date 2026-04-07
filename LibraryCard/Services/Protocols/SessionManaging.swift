import Foundation
import SwiftData

/// Protocol for session lifecycle management.
/// Enables dependency injection and testability.
@MainActor
protocol SessionManaging: ObservableObject {
    var activeSession: DrinkingSession? { get }
    var isSessionActive: Bool { get }
    var elapsedTime: TimeInterval { get }

    func startSession(user: User?, venue: Venue?, in context: ModelContext)
    func endSession(in context: ModelContext)
    func cancelSession(in context: ModelContext)
    func addDrink(
        type: DrinkType,
        name: String,
        sizeMl: Double,
        alcoholPercentage: Double,
        price: Double?,
        venue: Venue?,
        in context: ModelContext
    )
}
