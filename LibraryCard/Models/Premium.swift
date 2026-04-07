import Foundation
import SwiftData

/// Premium subscription tier.
@Model
final class PremiumSubscription {
    var id: UUID
    var userId: UUID
    var tier: PremiumTier
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
    var receiptData: String?

    init(
        userId: UUID,
        tier: PremiumTier
    ) {
        self.id = UUID()
        self.userId = userId
        self.tier = tier
        self.startDate = Date()
        self.endDate = nil
        self.isActive = true
        self.receiptData = nil
    }

    var isExpired: Bool {
        guard let endDate = endDate else { return false }
        return endDate < Date()
    }
}

enum PremiumTier: String, Codable, CaseIterable {
    case individual = "Individual"
    case organization = "Organization"

    var features: [String] {
        switch self {
        case .individual:
            return [
                "Pre-swipe on planned bar-goers",
                "Advanced Wrapped analytics",
                "Unlimited photo posts per session",
                "Priority matching",
                "Custom organization themes"
            ]
        case .organization:
            return [
                "All Individual features",
                "Org-wide leaderboards & Wrapped",
                "Inter-org showdowns",
                "Custom org branding",
                "Admin analytics dashboard",
                "Priority support"
            ]
        }
    }
}

/// ID verification to enforce 21+ age requirement.
@Model
final class IDVerification {
    var id: UUID
    var userId: UUID
    var status: VerificationStatus
    var dateOfBirth: Date?
    var submittedAt: Date
    var verifiedAt: Date?
    var rejectionReason: String?

    /// Whether the user is 21+ based on their verified DOB
    var isOfAge: Bool {
        guard let dob = dateOfBirth else { return false }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
        return (ageComponents.year ?? 0) >= 21
    }

    init(userId: UUID) {
        self.id = UUID()
        self.userId = userId
        self.status = .pending
        self.dateOfBirth = nil
        self.submittedAt = Date()
        self.verifiedAt = nil
        self.rejectionReason = nil
    }

    func verify(dateOfBirth: Date) {
        self.dateOfBirth = dateOfBirth
        self.verifiedAt = Date()
        self.status = isOfAge ? .verified : .rejected
        if !isOfAge {
            self.rejectionReason = "Must be 21 or older."
        }
    }

    func reject(reason: String) {
        self.status = .rejected
        self.rejectionReason = reason
    }
}

enum VerificationStatus: String, Codable {
    case pending = "Pending"
    case verified = "Verified"
    case rejected = "Rejected"
    case expired = "Expired"
}
