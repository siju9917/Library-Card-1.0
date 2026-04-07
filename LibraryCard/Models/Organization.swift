import Foundation
import SwiftData

@Model
final class Organization {
    var id: UUID
    var name: String
    var handle: String
    var bio: String?
    var imageData: Data?
    var createdAt: Date
    var isPremium: Bool

    @Relationship(deleteRule: .cascade, inverse: \OrganizationMember.organization)
    var members: [OrganizationMember] = []

    init(
        name: String,
        handle: String,
        bio: String? = nil,
        isPremium: Bool = false
    ) {
        self.id = UUID()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.handle = handle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.bio = bio
        self.imageData = nil
        self.createdAt = Date()
        self.isPremium = isPremium
    }

    // MARK: - Aggregate Stats

    var memberCount: Int {
        members.filter { $0.status == .active }.count
    }

    /// Total drinks across all members, all time
    var totalOrgDrinks: Int {
        members
            .filter { $0.status == .active }
            .compactMap { $0.user }
            .reduce(0) { $0 + $1.totalLifetimeDrinks }
    }

    /// Top performers by lifetime drinks
    var leaderboard: [(member: OrganizationMember, drinks: Int)] {
        members
            .filter { $0.status == .active }
            .compactMap { member -> (OrganizationMember, Int)? in
                guard let user = member.user else { return nil }
                return (member, user.totalLifetimeDrinks)
            }
            .sorted { $0.1 > $1.1 }
    }
}

@Model
final class OrganizationMember {
    var id: UUID
    var user: User?
    var organization: Organization?
    var role: OrgRole
    var status: OrgMemberStatus
    var joinedAt: Date

    init(
        user: User?,
        organization: Organization?,
        role: OrgRole = .member
    ) {
        self.id = UUID()
        self.user = user
        self.organization = organization
        self.role = role
        self.status = .active
        self.joinedAt = Date()
    }
}

enum OrgRole: String, Codable, CaseIterable {
    case owner = "Owner"
    case admin = "Admin"
    case member = "Member"
}

enum OrgMemberStatus: String, Codable, CaseIterable {
    case active = "Active"
    case invited = "Invited"
    case removed = "Removed"
}
