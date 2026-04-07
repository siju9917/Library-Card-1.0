import Foundation
import SwiftData

/// Tracks the order of bars visited during a session with timestamps.
/// Helps friends track each other and provides a "bar crawl" recap.
@Model
final class BarCheckIn {
    var id: UUID
    var session: DrinkingSession?
    var venue: Venue?
    var arrivedAt: Date
    var departedAt: Date?
    var orderIndex: Int

    init(
        session: DrinkingSession?,
        venue: Venue?,
        orderIndex: Int
    ) {
        self.id = UUID()
        self.session = session
        self.venue = venue
        self.arrivedAt = Date()
        self.departedAt = nil
        self.orderIndex = orderIndex
    }

    var isCurrentlyHere: Bool {
        departedAt == nil
    }

    var durationAtVenue: TimeInterval {
        let end = departedAt ?? Date()
        return end.timeIntervalSince(arrivedAt)
    }

    var durationFormatted: String {
        let minutes = Int(durationAtVenue / 60)
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }

    func depart() {
        departedAt = Date()
    }
}
