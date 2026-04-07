import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = AppColor.primary
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(AppFont.statValue)
                .foregroundStyle(AppColor.textPrimary)

            Text(title)
                .font(AppFont.statLabel)
                .foregroundStyle(AppColor.textSecondary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(AppFont.caption2)
                    .foregroundStyle(AppColor.textTertiary)
            }
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

#Preview {
    HStack {
        StatCard(
            title: "Drinks This Week",
            value: "12",
            icon: "mug.fill",
            subtitle: "+3 from last week"
        )
        StatCard(
            title: "Total Spent",
            value: "$87.50",
            icon: "dollarsign.circle.fill",
            color: AppColor.success
        )
    }
    .padding()
}
