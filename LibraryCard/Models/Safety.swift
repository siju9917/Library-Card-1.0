import Foundation
import SwiftData

/// SOS alert sent by a user to their emergency contacts / friends.
@Model
final class SOSAlert {
    var id: UUID
    var userId: UUID
    var userDisplayName: String
    var latitude: Double?
    var longitude: Double?
    var venueName: String?
    var message: String
    var timestamp: Date
    var status: SOSStatus

    /// IDs of friends who were notified
    var notifiedFriendIds: [UUID]

    /// IDs of friends who acknowledged
    var acknowledgedFriendIds: [UUID]

    init(
        userId: UUID,
        userDisplayName: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        venueName: String? = nil,
        message: String = "I need help. Here's my location."
    ) {
        self.id = UUID()
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.latitude = latitude
        self.longitude = longitude
        self.venueName = venueName
        self.message = message
        self.timestamp = Date()
        self.status = .active
        self.notifiedFriendIds = []
        self.acknowledgedFriendIds = []
    }

    func resolve() {
        status = .resolved
    }

    func acknowledge(friendId: UUID) {
        if !acknowledgedFriendIds.contains(friendId) {
            acknowledgedFriendIds.append(friendId)
        }
    }
}

enum SOSStatus: String, Codable {
    case active = "Active"
    case resolved = "Resolved"
    case expired = "Expired"
}

/// Departure notification — alerts friends when someone leaves a venue.
@Model
final class DepartureNotification {
    var id: UUID
    var userId: UUID
    var userDisplayName: String
    var venueName: String
    var departedAt: Date
    var notifiedFriendIds: [UUID]

    init(
        userId: UUID,
        userDisplayName: String,
        venueName: String
    ) {
        self.id = UUID()
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.venueName = venueName
        self.departedAt = Date()
        self.notifiedFriendIds = []
    }
}
