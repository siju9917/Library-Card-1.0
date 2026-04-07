import Foundation
import SwiftData

/// Tinder-style swipe matching at a bar.
/// Users can swipe on others at the same venue. Mutual swipes create a match.
@Model
final class SwipeAction {
    var id: UUID
    var swiperUserId: UUID
    var swiperDisplayName: String
    var targetUserId: UUID
    var targetDisplayName: String
    var venueId: UUID?
    var venueName: String?
    var direction: SwipeDirection
    var timestamp: Date

    init(
        swiperUserId: UUID,
        swiperDisplayName: String,
        targetUserId: UUID,
        targetDisplayName: String,
        venueId: UUID? = nil,
        venueName: String? = nil,
        direction: SwipeDirection
    ) {
        self.id = UUID()
        self.swiperUserId = swiperUserId
        self.swiperDisplayName = swiperDisplayName
        self.targetUserId = targetUserId
        self.targetDisplayName = targetDisplayName
        self.venueId = venueId
        self.venueName = venueName
        self.direction = direction
        self.timestamp = Date()
    }
}

enum SwipeDirection: String, Codable {
    case left = "Pass"
    case right = "Like"
}

/// A mutual match between two users.
@Model
final class Match {
    var id: UUID
    var userOneId: UUID
    var userOneName: String
    var userTwoId: UUID
    var userTwoName: String
    var venueId: UUID?
    var venueName: String?
    var matchedAt: Date
    var status: MatchStatus
    var hasMessaged: Bool

    init(
        userOneId: UUID,
        userOneName: String,
        userTwoId: UUID,
        userTwoName: String,
        venueId: UUID? = nil,
        venueName: String? = nil
    ) {
        self.id = UUID()
        self.userOneId = userOneId
        self.userOneName = userOneName
        self.userTwoId = userTwoId
        self.userTwoName = userTwoName
        self.venueId = venueId
        self.venueName = venueName
        self.matchedAt = Date()
        self.status = .active
        self.hasMessaged = false
    }

    func otherUserName(currentUserId: UUID) -> String {
        currentUserId == userOneId ? userTwoName : userOneName
    }

    func otherUserId(currentUserId: UUID) -> UUID {
        currentUserId == userOneId ? userTwoId : userOneId
    }
}

enum MatchStatus: String, Codable {
    case active = "Active"
    case expired = "Expired"
    case blocked = "Blocked"
}

/// Premium pre-swipe: swipe on people planning to go out.
/// If they show up at the bar and also swiped, you both get notified.
@Model
final class PreSwipe {
    var id: UUID
    var swiperUserId: UUID
    var targetUserId: UUID
    var targetDisplayName: String
    var plannedVenueId: UUID?
    var plannedVenueName: String?
    var plannedDate: Date
    var createdAt: Date
    var status: PreSwipeStatus

    init(
        swiperUserId: UUID,
        targetUserId: UUID,
        targetDisplayName: String,
        plannedVenueId: UUID? = nil,
        plannedVenueName: String? = nil,
        plannedDate: Date
    ) {
        self.id = UUID()
        self.swiperUserId = swiperUserId
        self.targetUserId = targetUserId
        self.targetDisplayName = targetDisplayName
        self.plannedVenueId = plannedVenueId
        self.plannedVenueName = plannedVenueName
        self.plannedDate = plannedDate
        self.createdAt = Date()
        self.status = .pending
    }
}

enum PreSwipeStatus: String, Codable {
    case pending = "Pending"
    case matched = "Matched"
    case expired = "Expired"
}
