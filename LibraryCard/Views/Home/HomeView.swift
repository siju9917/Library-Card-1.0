import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var sessionManager: SessionManager
    @Query(
        filter: #Predicate<DrinkingSession> { $0.endTime != nil },
        sort: \DrinkingSession.startTime,
        order: .reverse
    )
    private var completedSessions: [DrinkingSession]

    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Active session banner
                    if sessionManager.isSessionActive {
                        ActiveSessionBanner()
                    }

                    // Quick stats
                    weeklyStatsSection

                    // Quick start
                    quickStartSection

                    // Recent sessions
                    recentSessionsSection

                    // Navigation links
                    navigationLinksSection
                }
                .padding()
            }
            .refreshable {
                viewModel.loadData(sessions: completedSessions)
            }
            .dismissKeyboardOnScroll()
            .navigationTitle("Library Card")
            .onAppear {
                viewModel.loadData(sessions: completedSessions)
            }
            .onChange(of: completedSessions.count) {
                viewModel.loadData(sessions: completedSessions)
            }
        }
    }

    private var weeklyStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            HStack(spacing: 12) {
                StatCard(
                    title: "Drinks",
                    value: "\(viewModel.totalDrinksThisWeek)",
                    icon: "mug.fill"
                )
                StatCard(
                    title: "All Time",
                    value: "\(viewModel.totalDrinksAllTime)",
                    icon: "trophy.fill",
                    color: .yellow
                )
            }

            HStack(spacing: 12) {
                StatCard(
                    title: "Avg/Session",
                    value: String(format: "%.1f", viewModel.averageDrinksPerSession),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
                StatCard(
                    title: "Dry Streak",
                    value: "\(viewModel.currentStreak) days",
                    icon: "flame.fill",
                    color: .red
                )
            }
        }
    }

    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start")
                .font(.headline)

            if !sessionManager.isSessionActive {
                Button {
                    sessionManager.startSession(user: nil, venue: nil, in: modelContext)
                } label: {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                        Text("Start a Session")
                    }
                    .primaryButtonStyle()
                }
            }
        }
    }

    private var navigationLinksSection: some View {
        VStack(spacing: 12) {
            NavigationLink {
                WrappedListView()
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Your Wrapped")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            NavigationLink {
                ShowdownView()
            } label: {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.orange)
                    Text("Showdown")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Sessions")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    SessionHistoryView()
                }
                .font(.caption)
                .foregroundStyle(AppColor.primary)
            }

            if viewModel.recentSessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No sessions yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Start your first session to see stats here")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(viewModel.recentSessions) { session in
                    NavigationLink(destination: SessionDetailView(session: session)) {
                        SessionSummaryCard(session: session)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ActiveSessionBanner: View {
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        HStack {
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)

            Text("Session Active")
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer()

            Text(formatDuration(sessionManager.elapsedTime))
                .font(.subheadline)
                .monospacedDigit()

            if let session = sessionManager.activeSession {
                Text("\(session.totalDrinks) drinks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.green.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct SessionHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<DrinkingSession> { $0.endTime != nil },
        sort: \DrinkingSession.startTime,
        order: .reverse
    )
    private var sessions: [DrinkingSession]

    var body: some View {
        Group {
            if sessions.isEmpty {
                EmptyStateView(
                    icon: "moon.zzz.fill",
                    title: "No Sessions Yet",
                    subtitle: "Your completed sessions will appear here."
                )
            } else {
                List {
                    ForEach(sessions) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            SessionSummaryCard(session: session)
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            modelContext.delete(sessions[index])
                        }
                        try? modelContext.save()
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("All Sessions")
    }
}
