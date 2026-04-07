import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \DrinkingSession.startTime, order: .reverse)
    private var allSessions: [DrinkingSession]

    @State private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period picker
                    periodPicker

                    // Summary cards
                    summaryCards

                    // Drinks over time chart
                    drinksOverTimeChart

                    // Spending over time chart
                    spendOverTimeChart

                    // Drink type breakdown
                    drinkTypeChart

                    // Day of week heatmap
                    dayOfWeekChart

                    // Top venues
                    topVenuesSection
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .onAppear {
                viewModel.loadStats(sessions: allSessions)
            }
            .onChange(of: viewModel.selectedPeriod) {
                viewModel.loadStats(sessions: allSessions)
            }
            .onChange(of: allSessions.count) {
                viewModel.loadStats(sessions: allSessions)
            }
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("Period", selection: $viewModel.selectedPeriod) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Total Drinks",
                    value: "\(viewModel.totalDrinks)",
                    icon: "mug.fill"
                )
                StatCard(
                    title: "Total Spent",
                    value: String(format: "$%.0f", viewModel.totalSpend),
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
            }
            HStack(spacing: 12) {
                StatCard(
                    title: "Avg Pace",
                    value: String(format: "%.1f/hr", viewModel.averageDrinksPerHour),
                    icon: "speedometer",
                    color: .orange
                )
                StatCard(
                    title: "Sessions",
                    value: "\(viewModel.totalSessions)",
                    icon: "calendar",
                    color: .blue
                )
            }
            HStack(spacing: 12) {
                StatCard(
                    title: "Avg/Session",
                    value: String(format: "%.1f drinks", viewModel.averageDrinksPerSession),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .cyan
                )
                StatCard(
                    title: "Calories",
                    value: String(format: "%.0f cal", viewModel.totalCalories),
                    icon: "flame.fill",
                    color: .red
                )
            }
        }
    }

    // MARK: - Drinks Over Time

    private var drinksOverTimeChart: some View {
        ChartSection(title: "Drinks Over Time", icon: "chart.line.uptrend.xyaxis") {
            if viewModel.drinksOverTime.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(viewModel.drinksOverTime) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Drinks", point.value)
                    )
                    .foregroundStyle(AppColor.primary.gradient)
                    .cornerRadius(4)
                }
                .chartYAxisLabel("Drinks")
                .frame(height: 200)
            }
        }
    }

    // MARK: - Spend Over Time

    private var spendOverTimeChart: some View {
        ChartSection(title: "Spending Over Time", icon: "dollarsign.circle") {
            if viewModel.spendOverTime.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(viewModel.spendOverTime) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Spend", point.value)
                    )
                    .foregroundStyle(.green)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Spend", point.value)
                    )
                    .foregroundStyle(.green.opacity(0.1))
                    .interpolationMethod(.catmullRom)
                }
                .chartYAxisLabel("$")
                .frame(height: 200)
            }
        }
    }

    // MARK: - Drink Type Distribution

    private var drinkTypeChart: some View {
        ChartSection(title: "Drink Types", icon: "chart.pie") {
            if viewModel.drinkTypeDistribution.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(viewModel.drinkTypeDistribution) { point in
                    SectorMark(
                        angle: .value("Count", point.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Type", point.type.rawValue))
                    .cornerRadius(4)
                }
                .chartLegend(position: .bottom, alignment: .center)
                .frame(height: 240)
            }
        }
    }

    // MARK: - Day of Week

    private var dayOfWeekChart: some View {
        ChartSection(title: "Drinks by Day of Week", icon: "calendar") {
            if viewModel.dayOfWeekDistribution.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(viewModel.dayOfWeekDistribution) { point in
                    BarMark(
                        x: .value("Day", point.day),
                        y: .value("Drinks", point.count)
                    )
                    .foregroundStyle(.orange.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 180)
            }
        }
    }

    // MARK: - Top Venues

    private var topVenuesSection: some View {
        ChartSection(title: "Top Venues", icon: "mappin.and.ellipse") {
            if viewModel.topVenues.isEmpty {
                emptyChartPlaceholder
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.topVenues) { venue in
                        HStack {
                            Text(venue.name)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Spacer()

                            Text("\(venue.visits) visits")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(String(format: "$%.0f", venue.totalSpend))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.green)
                        }
                        .padding(.vertical, 4)

                        if venue.id != viewModel.topVenues.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("No data yet")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }
}

// MARK: - Chart Section Container

struct ChartSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(AppColor.primary)
                Text(title)
                    .font(.headline)
            }

            content
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
