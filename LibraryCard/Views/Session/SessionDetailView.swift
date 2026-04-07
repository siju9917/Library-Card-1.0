import SwiftUI
import Charts

struct SessionDetailView: View {
    let session: DrinkingSession

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Hero header
                heroHeader

                // Key metrics grid
                metricsGrid

                // Pace chart (drinks over time within session)
                paceChart

                // Drink breakdown
                drinkBreakdown

                // Drink timeline
                drinkTimeline

                // BAC estimate section
                if let bac = session.estimatedBAC {
                    bacSection(bac: bac)
                }

                // Venue info
                if let venue = session.venue {
                    venueSection(venue: venue)
                }
            }
            .padding()
        }
        .navigationTitle("Session Recap")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: AppSpacing.md) {
            // Date & venue
            VStack(spacing: AppSpacing.xs) {
                Text(session.venue?.name ?? "Night Out")
                    .font(AppFont.largeTitle)

                Text(session.startTime, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.textSecondary)

                if let endTime = session.endTime {
                    Text("\(session.startTime, format: .dateTime.hour().minute()) - \(endTime, format: .dateTime.hour().minute())")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textTertiary)
                }
            }

            // Big number: total drinks
            VStack(spacing: AppSpacing.xxs) {
                Text("\(session.totalDrinks)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.primary)
                Text("drinks")
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(session.totalDrinks) drinks total")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppSpacing.md) {
            MetricCell(
                value: session.durationFormatted,
                label: "Duration",
                icon: "clock.fill"
            )
            MetricCell(
                value: String(format: "%.1f/hr", session.drinksPerHour),
                label: "Pace",
                icon: "speedometer"
            )
            MetricCell(
                value: session.totalSpend > 0 ? String(format: "$%.0f", session.totalSpend) : "--",
                label: "Spent",
                icon: "dollarsign.circle.fill"
            )
            MetricCell(
                value: String(format: "%.1f", session.standardUnits),
                label: "Std Drinks",
                icon: "drop.fill"
            )
            MetricCell(
                value: session.totalSpend > 0 ? String(format: "$%.2f", session.averageDrinkPrice) : "--",
                label: "Avg Price",
                icon: "tag.fill"
            )
            MetricCell(
                value: "\(Int(session.drinks.reduce(0) { $0 + $1.calories })) cal",
                label: "Calories",
                icon: "flame.fill"
            )
        }
        .cardStyle()
    }

    // MARK: - Pace Chart

    private var paceChart: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(AppColor.primary)
                Text("Pace Over Time")
                    .font(AppFont.headline)
            }

            if session.drinks.count >= 2 {
                let cumulativeDrinks = buildCumulativeDrinks()

                Chart(cumulativeDrinks) { point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("Drinks", point.count)
                    )
                    .foregroundStyle(AppColor.primary)
                    .interpolationMethod(.stepEnd)

                    PointMark(
                        x: .value("Time", point.time),
                        y: .value("Drinks", point.count)
                    )
                    .foregroundStyle(AppColor.primary)
                    .symbolSize(30)
                }
                .chartYAxisLabel("Total Drinks")
                .frame(height: 200)
            } else {
                Text("Need at least 2 drinks to show pace chart.")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
            }
        }
        .cardStyle()
    }

    // MARK: - Drink Breakdown

    private var drinkBreakdown: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "chart.pie")
                    .foregroundStyle(AppColor.primary)
                Text("Drink Breakdown")
                    .font(AppFont.headline)
            }

            if !session.drinks.isEmpty {
                let breakdown = session.drinkTypeBreakdown.sorted { $0.value > $1.value }

                Chart(breakdown, id: \.key) { item in
                    SectorMark(
                        angle: .value("Count", item.value),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Type", item.key.rawValue))
                    .cornerRadius(4)
                }
                .chartLegend(position: .bottom, alignment: .center)
                .frame(height: 200)

                // Text breakdown
                ForEach(breakdown, id: \.key) { type, count in
                    HStack {
                        Image(systemName: type.icon)
                            .foregroundStyle(AppColor.primary)
                            .frame(width: 24)
                        Text(type.rawValue)
                            .font(AppFont.subheadline)
                        Spacer()
                        Text("\(count)")
                            .font(AppFont.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            } else {
                Text("No drinks logged.")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiary)
            }
        }
        .cardStyle()
    }

    // MARK: - Drink Timeline

    private var drinkTimeline: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "list.bullet.below.rectangle")
                    .foregroundStyle(AppColor.primary)
                Text("Timeline")
                    .font(AppFont.headline)
            }

            let sortedDrinks = session.drinks.sorted { $0.timestamp < $1.timestamp }

            ForEach(Array(sortedDrinks.enumerated()), id: \.element.id) { index, drink in
                HStack(spacing: AppSpacing.md) {
                    // Timeline dot and line
                    VStack(spacing: 0) {
                        Circle()
                            .fill(AppColor.primary)
                            .frame(width: 10, height: 10)

                        if index < sortedDrinks.count - 1 {
                            Rectangle()
                                .fill(AppColor.primary.opacity(0.3))
                                .frame(width: 2, height: 30)
                        }
                    }

                    // Drink info
                    HStack {
                        Image(systemName: drink.type.icon)
                            .foregroundStyle(AppColor.primary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text(drink.name)
                                .font(AppFont.subheadline)
                                .fontWeight(.medium)
                            Text("\(drink.sizeFormatted) \u{2022} \(String(format: "%.1f%%", drink.alcoholPercentage))")
                                .font(AppFont.caption2)
                                .foregroundStyle(AppColor.textTertiary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                            if let price = drink.price {
                                Text(String(format: "$%.2f", price))
                                    .font(AppFont.subheadline)
                                    .fontWeight(.medium)
                            }
                            Text(drink.timestamp, format: .dateTime.hour().minute())
                                .font(AppFont.caption2)
                                .foregroundStyle(AppColor.textTertiary)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(drink.name), \(drink.sizeFormatted), at \(drink.timestamp, format: .dateTime.hour().minute())")
            }
        }
        .cardStyle()
    }

    // MARK: - BAC Section

    private func bacSection(bac: Double) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundStyle(AppColor.bacColor(for: bac))
                Text("Estimated BAC")
                    .font(AppFont.headline)
            }

            HStack {
                Text(String(format: "%.3f%%", bac))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.bacColor(for: bac))

                Spacer()

                VStack(alignment: .trailing) {
                    Text(bacLabel(bac))
                        .font(AppFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.bacColor(for: bac))
                }
            }

            Text("This is a rough estimate based on weight, sex, drinks consumed, and time elapsed. Do not use this for safety decisions. Never drink and drive.")
                .font(AppFont.caption2)
                .foregroundStyle(AppColor.textTertiary)
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Estimated BAC: \(String(format: "%.3f", bac)) percent. \(bacLabel(bac)). This is an estimate only.")
    }

    // MARK: - Venue Section

    private func venueSection(venue: Venue) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(AppColor.primary)
                Text("Venue")
                    .font(AppFont.headline)
            }

            HStack {
                Image(systemName: venue.category.icon)
                    .foregroundStyle(AppColor.primary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(venue.name)
                        .font(AppFont.subheadline)
                        .fontWeight(.medium)
                    if let address = venue.address {
                        Text(address)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    Text("\(venue.visitCount) total visits \u{2022} \(venue.averageSpendPerVisit.currencyFormatted) avg")
                        .font(AppFont.caption2)
                        .foregroundStyle(AppColor.textTertiary)
                }

                Spacer()
            }
        }
        .cardStyle()
    }

    // MARK: - Helpers

    private func buildCumulativeDrinks() -> [CumulativeDrinkPoint] {
        let sorted = session.drinks.sorted { $0.timestamp < $1.timestamp }
        var points: [CumulativeDrinkPoint] = []

        // Start at 0
        if let first = sorted.first {
            points.append(CumulativeDrinkPoint(time: first.timestamp.addingTimeInterval(-1), count: 0))
        }

        for (index, drink) in sorted.enumerated() {
            points.append(CumulativeDrinkPoint(time: drink.timestamp, count: index + 1))
        }

        return points
    }

    private func bacLabel(_ bac: Double) -> String {
        if bac < 0.02 { return "Minimal" }
        if bac < 0.04 { return "Light" }
        if bac < 0.06 { return "Moderate" }
        if bac < 0.08 { return "Impaired" }
        return "Over Legal Limit"
    }
}

// MARK: - Supporting Types

struct CumulativeDrinkPoint: Identifiable {
    let id = UUID()
    let time: Date
    let count: Int
}

struct MetricCell: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppColor.primary)

            Text(value)
                .font(AppFont.subheadline)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(AppFont.caption2)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
