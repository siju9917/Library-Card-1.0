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
                VStack(spacing: AppSpacing.xl) {
                    periodPicker
                    summaryCards
                    drinksOverTimeChart
                    dpmOverTimeChart
                    drinkTypeChart
                    dayOfWeekChart
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

    private var periodPicker: some View {
        Picker("Period", selection: $viewModel.selectedPeriod) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    private var summaryCards: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                StatCard(title: "Total Drinks", value: "\(viewModel.totalDrinks)", icon: "mug.fill")
                StatCard(title: "Avg DPM", value: String(format: "%.3f", viewModel.averageDPM), icon: "gauge.with.needle.fill", color: AppColor.info)
            }
            HStack(spacing: AppSpacing.md) {
                StatCard(title: "Avg Pace", value: String(format: "%.1f/hr", viewModel.averageDrinksPerHour), icon: "speedometer", color: .orange)
                StatCard(title: "Sessions", value: "\(viewModel.totalSessions)", icon: "calendar", color: AppColor.info)
            }
            HStack(spacing: AppSpacing.md) {
                StatCard(title: "Avg/Session", value: String(format: "%.1f drinks", viewModel.averageDrinksPerSession), icon: "chart.line.uptrend.xyaxis", color: .cyan)
                StatCard(title: "Calories", value: String(format: "%.0f cal", viewModel.totalCalories), icon: "flame.fill", color: AppColor.danger)
            }
        }
    }

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

    private var dpmOverTimeChart: some View {
        ChartSection(title: "DPM Over Time", icon: "gauge.with.needle.fill") {
            if viewModel.dpmOverTime.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(viewModel.dpmOverTime) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("DPM", point.value)
                    )
                    .foregroundStyle(AppColor.info)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("DPM", point.value)
                    )
                    .foregroundStyle(AppColor.info.opacity(0.1))
                    .interpolationMethod(.catmullRom)
                }
                .chartYAxisLabel("DPM")
                .frame(height: 200)
            }
        }
    }

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

    private var topVenuesSection: some View {
        ChartSection(title: "Top Venues", icon: "mappin.and.ellipse") {
            if viewModel.topVenues.isEmpty {
                emptyChartPlaceholder
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.topVenues) { venue in
                        HStack {
                            Text(venue.name)
                                .font(AppFont.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(venue.visits) visits")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        .padding(.vertical, AppSpacing.xs)

                        if venue.id != viewModel.topVenues.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "chart.bar.xaxis")
                .font(.title)
                .foregroundStyle(AppColor.textSecondary)
            Text("No data yet")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }
}

struct ChartSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(AppColor.primary)
                Text(title)
                    .font(AppFont.headline)
            }
            content
        }
        .cardStyle()
    }
}
