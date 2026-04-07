import Foundation
import SwiftData

@Model
final class Friendship {
    var id: UUID
    var user: User?
    var friendUserId: UUID
    var friendDisplayName: String
    var friendUsername: String
    var status: FriendshipStatus
    var createdAt: Date

    init(
        user: User?,
        friendUserId: UUID,
        friendDisplayName: String,
        friendUsername: String,
        status: FriendshipStatus = .pending
    ) {
        self.id = UUID()
        self.user = user
        self.friendUserId = friendUserId
        self.friendDisplayName = friendDisplayName
        self.friendUsername = friendUsername
        self.status = status
        self.createdAt = Date()
    }
}

enum FriendshipStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case accepted = "Accepted"
    case blocked = "Blocked"
}
