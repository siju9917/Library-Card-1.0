import SwiftUI
import SwiftData

struct ShowdownView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject var showdownManager = ShowdownManager()
    @State private var showingSetup = false

    var body: some View {
        NavigationStack {
            Group {
                if let showdown = showdownManager.activeShowdown {
                    if showdown.isActive {
                        liveShowdownView(showdown)
                    } else if showdown.status == .setup {
                        showdownSetupView(showdown)
                    } else {
                        showdownResultsView(showdown)
                    }
                } else {
                    startShowdownView
                }
            }
            .navigationTitle("Showdown")
        }
    }

    // MARK: - Start

    private var startShowdownView: some View {
        VStack(spacing: AppSpacing.xxl) {
            Spacer()

            Image(systemName: "flag.2.crossed.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppColor.primary)

            VStack(spacing: AppSpacing.sm) {
                Text("Showdown Mode")
                    .font(AppFont.largeTitle)
                Text("Challenge another team to a session-long drinking showdown. Track every drink in real time.")
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxxl)
            }

            Button {
                showingSetup = true
            } label: {
                Text("Create Showdown")
                    .primaryButtonStyle()
            }
            .padding(.horizontal, AppSpacing.xxxl)

            Spacer()
        }
        .sheet(isPresented: $showingSetup) {
            ShowdownSetupSheet(showdownManager: showdownManager)
        }
    }

    // MARK: - Setup

    private func showdownSetupView(_ showdown: Showdown) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                Text(showdown.name)
                    .font(AppFont.title)

                ForEach(showdown.teams) { team in
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text(team.name)
                            .font(AppFont.headline)

                        if team.participants.isEmpty {
                            Text("No members yet")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.textTertiary)
                        }

                        ForEach(team.participants) { participant in
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(AppColor.primary)
                                Text(participant.displayName)
                                    .font(AppFont.subheadline)
                            }
                        }
                    }
                    .cardStyle()
                }

                Button {
                    showdownManager.startShowdown(in: modelContext)
                } label: {
                    Text("Start Showdown")
                        .primaryButtonStyle()
                }
                .disabled(showdown.teams.contains { $0.participants.isEmpty })
            }
            .padding()
        }
    }

    // MARK: - Live

    private func liveShowdownView(_ showdown: Showdown) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Status
                HStack {
                    Circle().fill(AppColor.success).frame(width: 8, height: 8)
                    Text("LIVE")
                        .font(AppFont.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColor.success)
                }

                Text(showdown.name)
                    .font(AppFont.title)

                // Scoreboard
                ForEach(showdown.scoreboard, id: \.team.id) { entry in
                    VStack(spacing: AppSpacing.sm) {
                        HStack {
                            Text(entry.team.name)
                                .font(AppFont.headline)
                            Spacer()
                            Text("\(entry.drinks)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColor.primary)
                        }

                        HStack {
                            Text(String(format: "%.2f DPM", entry.dpm))
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.textSecondary)
                            Spacer()
                            Text("\(entry.team.memberCount) members")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.textTertiary)
                        }

                        // Per-participant scores
                        ForEach(entry.team.participants) { participant in
                            HStack {
                                Text(participant.displayName)
                                    .font(AppFont.caption)
                                Spacer()
                                Text("\(participant.drinkCount) drinks")
                                    .font(AppFont.caption)
                                    .fontWeight(.medium)

                                Button {
                                    showdownManager.logDrink(for: participant, in: modelContext)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(AppColor.primary)
                                }
                            }
                            .padding(.leading, AppSpacing.lg)
                        }
                    }
                    .cardStyle()
                }

                // End button
                Button {
                    showdownManager.endShowdown(in: modelContext)
                } label: {
                    Text("End Showdown")
                        .destructiveButtonStyle()
                }
            }
            .padding()
        }
    }

    // MARK: - Results

    private func showdownResultsView(_ showdown: Showdown) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.yellow)

                if let winner = showdown.winningTeam {
                    Text("\(winner.name) Wins!")
                        .font(AppFont.largeTitle)
                }

                ForEach(showdown.scoreboard, id: \.team.id) { entry in
                    HStack {
                        Text(entry.team.name)
                            .font(AppFont.headline)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(entry.drinks) drinks")
                                .font(AppFont.subheadline)
                                .fontWeight(.bold)
                            Text(String(format: "%.2f DPM", entry.dpm))
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                    .cardStyle()
                }

                Button {
                    showdownManager.activeShowdown = nil
                } label: {
                    Text("Done")
                        .primaryButtonStyle()
                }
            }
            .padding()
        }
    }
}

// MARK: - Setup Sheet

struct ShowdownSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var showdownManager: ShowdownManager
    @State private var showdownName = ""
    @State private var team1Name = "Team 1"
    @State private var team2Name = "Team 2"

    var body: some View {
        NavigationStack {
            Form {
                Section("Showdown Name") {
                    TextField("Friday Night Showdown", text: $showdownName)
                }
                Section("Teams") {
                    TextField("Team 1 Name", text: $team1Name)
                    TextField("Team 2 Name", text: $team2Name)
                }
            }
            .navigationTitle("New Showdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        showdownManager.createShowdown(
                            name: showdownName.isEmpty ? "Showdown" : showdownName,
                            teamNames: [team1Name, team2Name],
                            session: nil,
                            in: modelContext
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
