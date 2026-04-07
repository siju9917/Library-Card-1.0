import SwiftUI
import SwiftData

struct WrappedListView: View {
    @Query(sort: \Wrapped.generatedAt, order: .reverse)
    private var wrappedRecaps: [Wrapped]

    @Query(sort: \DrinkingSession.startTime, order: .reverse)
    private var allSessions: [DrinkingSession]

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Generate buttons
                    generateSection

                    // Past wrappeds
                    if wrappedRecaps.isEmpty {
                        VStack(spacing: AppSpacing.md) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(AppColor.textTertiary)
                            Text("No Wrappeds Yet")
                                .font(AppFont.headline)
                            Text("Generate your first recap to see your drinking stats in style.")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(minHeight: 200)
                    } else {
                        ForEach(wrappedRecaps) { wrapped in
                            NavigationLink(destination: WrappedDetailView(wrapped: wrapped)) {
                                WrappedPreviewCard(wrapped: wrapped)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Wrapped")
        }
    }

    private var generateSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Generate Recap")
                .font(AppFont.headline)

            HStack(spacing: AppSpacing.md) {
                ForEach(WrappedPeriod.allCases, id: \.self) { period in
                    Button {
                        generateWrapped(period: period)
                    } label: {
                        VStack(spacing: AppSpacing.sm) {
                            Image(systemName: period.icon)
                                .font(.title3)
                            Text(period.rawValue)
                                .font(AppFont.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func generateWrapped(period: WrappedPeriod) {
        let range = WrappedGenerator.periodRange(for: period)
        let wrapped = WrappedGenerator.generate(
            userId: UUID(), // TODO: get actual user ID
            sessions: allSessions,
            period: period,
            periodStart: range.start,
            periodEnd: range.end
        )
        modelContext.insert(wrapped)
        try? modelContext.save()
    }
}

// MARK: - Preview Card

struct WrappedPreviewCard: View {
    let wrapped: Wrapped

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: wrapped.period.icon)
                    .foregroundStyle(AppColor.primary)
                Text(wrapped.period.displayName)
                    .font(AppFont.headline)
                Spacer()
                Text(wrapped.generatedAt, format: .dateTime.month().day())
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            HStack(spacing: AppSpacing.xl) {
                VStack {
                    Text("\(wrapped.totalDrinks)")
                        .font(AppFont.statValue)
                    Text("Drinks")
                        .font(AppFont.caption2)
                        .foregroundStyle(AppColor.textSecondary)
                }
                VStack {
                    Text("\(wrapped.totalSessions)")
                        .font(AppFont.statValue)
                    Text("Sessions")
                        .font(AppFont.caption2)
                        .foregroundStyle(AppColor.textSecondary)
                }
                VStack {
                    Text(String(format: "%.3f", wrapped.averageDPM))
                        .font(AppFont.statValue)
                    Text("Avg DPM")
                        .font(AppFont.caption2)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Detail View

struct WrappedDetailView: View {
    let wrapped: Wrapped

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xxl) {
                // Hero
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: wrapped.period.icon)
                        .font(.system(size: 56))
                        .foregroundStyle(AppColor.primary)

                    Text("Your \(wrapped.period.displayName)")
                        .font(AppFont.largeTitle)

                    Text("\(wrapped.periodStart, format: .dateTime.month().day()) - \(wrapped.periodEnd, format: .dateTime.month().day())")
                        .font(AppFont.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                }

                // Big number
                VStack(spacing: AppSpacing.xs) {
                    Text("\(wrapped.totalDrinks)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColor.primary)
                    Text("total drinks")
                        .font(AppFont.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                }

                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                    StatCard(title: "Sessions", value: "\(wrapped.totalSessions)", icon: "calendar")
                    StatCard(title: "Avg DPM", value: String(format: "%.3f", wrapped.averageDPM), icon: "speedometer", color: AppColor.info)
                    StatCard(title: "Peak DPM", value: String(format: "%.3f", wrapped.peakDPM), icon: "flame.fill", color: AppColor.danger)
                    StatCard(title: "Std Drinks", value: String(format: "%.1f", wrapped.totalStandardUnits), icon: "drop.fill", color: AppColor.success)
                }

                // Drink of choice
                VStack(spacing: AppSpacing.md) {
                    Text("Drink of Choice")
                        .font(AppFont.headline)
                    Text(wrapped.topDrinkType)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColor.primary)
                    Text("\(wrapped.topDrinkTypeCount) times")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .cardStyle()

                // Top venue
                if let venue = wrapped.topVenueName {
                    VStack(spacing: AppSpacing.md) {
                        Text("Top Venue")
                            .font(AppFont.headline)
                        Text(venue)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColor.primary)
                        Text("\(wrapped.topVenueVisits) visits \u{2022} \(wrapped.uniqueVenuesVisited) unique venues")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .cardStyle()
                }

                // Fun stats
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Fun Stats")
                        .font(AppFont.headline)

                    HStack {
                        Text("Longest Session")
                        Spacer()
                        Text(String(format: "%.0f min", wrapped.longestSessionMinutes))
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("Busiest Day")
                        Spacer()
                        Text("\(wrapped.busiestDayOfWeek) (\(wrapped.busiestDayDrinks) drinks)")
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("Total Calories")
                        Spacer()
                        Text(String(format: "%.0f cal", wrapped.totalCalories))
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("Minutes Out")
                        Spacer()
                        Text(String(format: "%.0f min", wrapped.totalMinutesOut))
                            .fontWeight(.semibold)
                    }
                }
                .font(AppFont.subheadline)
                .cardStyle()
            }
            .padding()
        }
        .navigationTitle(wrapped.period.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
