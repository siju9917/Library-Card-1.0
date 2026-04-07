import SwiftUI

struct SessionSummaryCard: View {
    let session: DrinkingSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.venue?.name ?? "Night Out")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(session.startTime, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusBadge(status: session.status)
            }

            Divider()

            // Stats grid
            HStack(spacing: 16) {
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
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct MiniStat: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.purple)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatusBadge: View {
    let status: SessionStatus

    var color: Color {
        switch status {
        case .active: return .green
        case .completed: return .blue
        case .cancelled: return .gray
        }
    }

    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
