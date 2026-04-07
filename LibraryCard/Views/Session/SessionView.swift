import SwiftUI
import SwiftData

struct SessionView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showingAddDrink = false
    @State private var showingEndConfirmation = false
    @State private var showingVenuePicker = false

    var body: some View {
        NavigationStack {
            Group {
                if sessionManager.isSessionActive {
                    activeSessionView
                } else {
                    startSessionView
                }
            }
            .navigationTitle("Session")
        }
    }

    // MARK: - Start Session

    private var startSessionView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "play.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppColor.primary)

            VStack(spacing: 8) {
                Text("Ready for a Night Out?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Start a session to track your drinks, spending, and pace in real time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                sessionManager.startSession(user: nil, venue: nil, in: modelContext)
            } label: {
                Text("Start Session")
                    .font(.headline)
                    .primaryButtonStyle()
            }
            .padding(.horizontal, 48)

            Spacer()
        }
    }

    // MARK: - Active Session

    private var activeSessionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Timer and core stats
                liveDashboard

                // Quick add drinks
                quickAddSection

                // Drinks log
                drinksLogSection

                // End session button
                endSessionSection
            }
            .padding()
        }
        .sheet(isPresented: $showingAddDrink) {
            AddDrinkSheet()
        }
        .confirmationDialog(
            "End Session?",
            isPresented: $showingEndConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Session") {
                sessionManager.endSession(in: modelContext)
            }
            Button("Cancel Session", role: .destructive) {
                sessionManager.cancelSession(in: modelContext)
            }
            Button("Keep Going", role: .cancel) {}
        }
    }

    private var liveDashboard: some View {
        VStack(spacing: 16) {
            // Timer
            Text(formatDuration(sessionManager.elapsedTime))
                .font(AppFont.timerDisplay)
                .foregroundStyle(AppColor.primary)
                .accessibilityLabel("Session time: \(sessionManager.elapsedTime.durationFormatted)")

            if let session = sessionManager.activeSession {
                // Live stats
                HStack(spacing: 24) {
                    VStack {
                        Text("\(session.totalDrinks)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Drinks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()
                        .frame(height: 40)

                    VStack {
                        Text(String(format: "%.1f", session.drinksPerHour))
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Per Hour")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()
                        .frame(height: 40)

                    VStack {
                        Text(String(format: "$%.0f", session.totalSpend))
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Spent")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // BAC estimate
                if let bac = session.estimatedBAC {
                    HStack {
                        Image(systemName: "heart.text.square.fill")
                            .foregroundStyle(AppColor.bacColor(for: bac))
                        Text(String(format: "Est. BAC: %.3f%%", bac))
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.bacColor(for: bac))
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColor.bacColor(for: bac).opacity(0.1))
                    .clipShape(Capsule())
                    .accessibilityLabel("Estimated blood alcohol: \(String(format: "%.3f", bac)) percent")
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Add")
                    .font(.headline)
                Spacer()
                Button("Custom") {
                    showingAddDrink = true
                }
                .font(.caption)
                .foregroundStyle(AppColor.primary)
            }

            DrinkQuickAddGrid { type in
                sessionManager.addDrink(
                    type: type,
                    name: type.rawValue,
                    sizeMl: type.defaultSizeMl,
                    alcoholPercentage: type.defaultAlcoholPercentage,
                    price: nil,
                    venue: sessionManager.activeSession?.venue,
                    in: modelContext
                )
            }
        }
    }

    private var drinksLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Drinks Log")
                .font(.headline)

            if let session = sessionManager.activeSession {
                if session.drinks.isEmpty {
                    Text("No drinks logged yet. Tap a drink above to add one.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    ForEach(session.drinks.sorted(by: { $0.timestamp > $1.timestamp })) { drink in
                        DrinkLogRow(drink: drink)
                    }
                }
            }
        }
    }

    private var endSessionSection: some View {
        Button {
            showingEndConfirmation = true
        } label: {
            Text("End Session")
                .font(.headline)
                .destructiveButtonStyle()
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

}

// MARK: - Drink Log Row

struct DrinkLogRow: View {
    let drink: Drink

    var body: some View {
        HStack {
            Image(systemName: drink.type.icon)
                .foregroundStyle(AppColor.primary)
                .frame(width: 28)

            VStack(alignment: .leading) {
                Text(drink.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(drink.sizeFormatted) - \(String(format: "%.1f%%", drink.alcoholPercentage))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                if let price = drink.price {
                    Text(String(format: "$%.2f", price))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Text(drink.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}
