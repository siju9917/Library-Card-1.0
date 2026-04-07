import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query(sort: \DrinkingSession.startTime, order: .reverse)
    private var sessions: [DrinkingSession]

    @State private var viewModel = ProfileViewModel()
    @State private var showingEditProfile = false

    private var currentUser: User? { users.first }

    var body: some View {
        NavigationStack {
            List {
                // Profile header
                profileHeader

                // Lifetime stats
                lifetimeStats

                // Wrapped
                wrappedSection

                // Settings
                settingsSection

                // About
                aboutSection
            }
            .navigationTitle("Profile")
            .onAppear {
                viewModel.loadProfile(user: currentUser, sessions: sessions)
                ensureUserExists()
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileSheet(user: currentUser)
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppColor.primary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(currentUser?.displayName ?? "Set Up Profile")
                        .font(.title3)
                        .fontWeight(.bold)

                    if let email = currentUser?.email {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("Member for \(viewModel.memberSinceDays) days")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Button {
                    showingEditProfile = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppColor.primary)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Lifetime Stats

    private var lifetimeStats: some View {
        Section("Lifetime Stats") {
            StatRow(label: "Total Sessions", value: "\(viewModel.totalSessions)")
            StatRow(label: "Total Drinks", value: "\(viewModel.totalLifetimeDrinks)")
            StatRow(label: "Avg DPM", value: String(format: "%.3f", viewModel.totalDPM))
            StatRow(label: "Favorite Venue", value: viewModel.favoriteVenue)
            StatRow(label: "Favorite Drink", value: viewModel.favoriteDrinkType)
        }
    }

    // MARK: - Wrapped

    private var wrappedSection: some View {
        Section {
            NavigationLink {
                WrappedListView()
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Your Wrapped")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        Section("Settings") {
            if let user = currentUser {
                HStack {
                    Text("Weekly Drink Goal")
                    Spacer()
                    Text(user.weeklyDrinkGoal.map { "\($0) drinks" } ?? "Not set")
                        .foregroundStyle(.secondary)
                }

                Toggle("Notifications", isOn: Binding(
                    get: { user.notificationsEnabled },
                    set: { user.notificationsEnabled = $0 }
                ))
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Build")
                Spacer()
                Text("1")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func ensureUserExists() {
        if users.isEmpty {
            let user = User(displayName: "New User")
            modelContext.insert(user)
            try? modelContext.save()
        }
    }
}

// MARK: - Supporting Views

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
        }
    }
}

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let user: User?

    @State private var displayName: String = ""
    @State private var weightKg: String = ""
    @State private var selectedSex: BiologicalSex = .preferNotToSay
    @State private var weeklyGoal: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal") {
                    TextField("Display Name", text: $displayName)
                    Picker("Biological Sex", selection: $selectedSex) {
                        ForEach(BiologicalSex.allCases, id: \.self) { sex in
                            Text(sex.rawValue).tag(sex)
                        }
                    }
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("kg", text: $weightKg)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kg")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Goals") {
                    HStack {
                        Text("Weekly Drink Limit")
                        Spacer()
                        TextField("0", text: $weeklyGoal)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("drinks")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Text("Weight and sex are used to estimate BAC. This is for informational purposes only and should not be relied upon for safety decisions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let user = user {
                    displayName = user.displayName
                    weightKg = user.weightKg.map { String(format: "%.1f", $0) } ?? ""
                    selectedSex = user.biologicalSex ?? .preferNotToSay
                    weeklyGoal = user.weeklyDrinkGoal.map { "\($0)" } ?? ""
                }
            }
        }
    }

    private func saveProfile() {
        guard let user = user else { return }
        user.displayName = displayName
        user.weightKg = Double(weightKg)
        user.biologicalSex = selectedSex
        user.weeklyDrinkGoal = Int(weeklyGoal)
        try? modelContext.save()
    }
}

