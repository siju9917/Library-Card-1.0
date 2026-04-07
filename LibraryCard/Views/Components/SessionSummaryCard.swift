import SwiftUI

struct SessionSummaryCard: View {
    let session: DrinkingSession

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(session.venue?.name ?? "Night Out")
                        .font(AppFont.headline)

                    Text(session.startTime, style: .date)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }

                Spacer()

                StatusBadge(status: session.status)
            }

            Divider()

            // Stats grid
            HStack(spacing: AppSpacing.lg) {
                MiniStat(
                    icon: "mug.fill",
                    value: "\(session.totalDrinks)",
                    label: "Drinks"
                )

                MiniStat(
                    icon: "clock.fill",
                    value: session.durationFormatted,
                    label: "Duration"
                )

                MiniStat(
                    icon: "speedometer",
                    value: String(format: "%.1f/hr", session.drinksPerHour),
                    label: "Pace"
                )

                if session.totalSpend > 0 {
                    MiniStat(
                        icon: "dollarsign.circle.fill",
                        value: String(format: "$%.0f", session.totalSpend),
                        label: "Spent"
                    )
                }
            }
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(session.venue?.name ?? "Night Out") on \(session.startTime, format: .dateTime.month().day()). \(session.totalDrinks) drinks, \(session.durationFormatted), \(String(format: "%.1f", session.drinksPerHour)) per hour"
        )
        .accessibilityHint("Tap to view session details")
    }
}

struct MiniStat: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppColor.primary)

            Text(value)
                .font(AppFont.subheadline)
                .fontWeight(.semibold)

            Text(label)
                .font(AppFont.caption2)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatusBadge: View {
    let status: SessionStatus

    var color: Color {
        switch status {
        case .active: return AppColor.success
        case .completed: return AppColor.info
        case .cancelled: return Color.gray
        }
    }

    var body: some View {
        Text(status.rawValue)
            .font(AppFont.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .accessibilityLabel("Status: \(status.rawValue)")
    }
}
