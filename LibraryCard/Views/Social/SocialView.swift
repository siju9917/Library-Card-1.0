import SwiftUI
import SwiftData

struct SocialView: View {
    @Query private var friendships: [Friendship]
    @Query private var organizations: [Organization]
    @State private var selectedSection: SocialSection = .friends
    @State private var showingAddFriend = false
    @State private var showingCreateOrg = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section picker
                Picker("Section", selection: $selectedSection) {
                    ForEach(SocialSection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedSection {
                case .friends:
                    friendsSection
                case .feed:
                    liveFeedSection
                case .organizations:
                    organizationsSection
                }
            }
            .navigationTitle("Social")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingAddFriend = true
                        } label: {
                            Label("Add Friend", systemImage: "person.badge.plus")
                        }
                        Button {
                            showingCreateOrg = true
                        } label: {
                            Label("Create Organization", systemImage: "building.2")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendSheet()
            }
            .sheet(isPresented: $showingCreateOrg) {
                CreateOrganizationSheet()
            }
        }
    }

    // MARK: - Friends

    private var friendsSection: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                if friendships.isEmpty {
                    emptyState(
                        icon: "person.2.fill",
                        title: "No Friends Yet",
                        subtitle: "Add friends to see their live sessions, share stats, and compete in showdowns."
                    )
                } else {
                    // Leaderboard
                    LeaderboardCard(
                        title: "Friends Leaderboard",
                        entries: friendships
                            .filter { $0.status == .accepted }
                            .map { LeaderboardEntry(name: $0.friendDisplayName, value: 0, metric: "lifetime drinks") }
                    )

                    // Friend list
                    ForEach(friendships.filter { $0.status == .accepted }) { friend in
                        FriendRow(friendship: friend)
                    }

                    // Pending
                    let pending = friendships.filter { $0.status == .pending }
                    if !pending.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Pending")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.textSecondary)
                            ForEach(pending) { friend in
                                FriendRow(friendship: friend)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Live Feed

    private var liveFeedSection: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                emptyState(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "Live Feed",
                    subtitle: "See your friends' live sessions, drink counts, and photos as they happen."
                )
            }
            .padding()
        }
    }

    // MARK: - Organizations

    private var organizationsSection: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                if organizations.isEmpty {
                    emptyState(
                        icon: "building.2.fill",
                        title: "No Organizations",
                        subtitle: "Create or join an organization to compete in group leaderboards."
                    )
                } else {
                    ForEach(organizations) { org in
                        NavigationLink(destination: OrganizationDetailView(organization: org)) {
                            OrgCard(organization: org)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(AppColor.textTertiary)
            Text(title)
                .font(AppFont.headline)
            Text(subtitle)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xxl)
            Spacer()
        }
        .frame(minHeight: 300)
    }
}

enum SocialSection: String, CaseIterable {
    case friends = "Friends"
    case feed = "Live Feed"
    case organizations = "Orgs"
}

// MARK: - Friend Row

struct FriendRow: View {
    let friendship: Friendship

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(AppColor.primary)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(friendship.friendDisplayName)
                    .font(AppFont.subheadline)
                    .fontWeight(.medium)
                Text("@\(friendship.friendUsername)")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            if friendship.status == .pending {
                Text("Pending")
                    .font(AppFont.caption2)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColor.warning.opacity(0.2))
                    .foregroundStyle(AppColor.warning)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Org Card

struct OrgCard: View {
    let organization: Organization

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundStyle(AppColor.primary)
                VStack(alignment: .leading) {
                    Text(organization.name)
                        .font(AppFont.headline)
                    Text("@\(organization.handle)")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                if organization.isPremium {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                }
            }

            HStack(spacing: AppSpacing.xl) {
                MiniStat(icon: "person.2.fill", value: "\(organization.memberCount)", label: "Members")
                MiniStat(icon: "mug.fill", value: "\(organization.totalOrgDrinks)", label: "Total Drinks")
            }
        }
        .cardStyle()
    }
}

// MARK: - Leaderboard Card

struct LeaderboardCard: View {
    let title: String
    let entries: [LeaderboardEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text(title)
                    .font(AppFont.headline)
            }

            if entries.isEmpty {
                Text("No data yet")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiary)
            } else {
                ForEach(Array(entries.prefix(5).enumerated()), id: \.offset) { index, entry in
                    HStack {
                        Text("#\(index + 1)")
                            .font(AppFont.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(index == 0 ? .yellow : index == 1 ? .gray : AppColor.textSecondary)
                            .frame(width: 28)

                        Text(entry.name)
                            .font(AppFont.subheadline)

                        Spacer()

                        Text("\(entry.value) \(entry.metric)")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }
        }
        .cardStyle()
    }
}

struct LeaderboardEntry {
    let name: String
    let value: Int
    let metric: String
}

// MARK: - Sheets

struct AddFriendSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                TextField("Search by username...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if searchText.isEmpty {
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(AppColor.textTertiary)
                        Text("Search for friends by username")
                            .font(AppFont.subheadline)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .frame(maxHeight: .infinity)
                }

                Spacer()
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct CreateOrganizationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var handle = ""
    @State private var bio = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Organization Info") {
                    TextField("Name", text: $name)
                    TextField("Handle (e.g. sigma_chi)", text: $handle)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Bio (optional)", text: $bio)
                }
            }
            .navigationTitle("Create Organization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let org = Organization(name: name, handle: handle, bio: bio.isEmpty ? nil : bio)
                        modelContext.insert(org)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.isEmpty || handle.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Organization Detail

struct OrganizationDetailView: View {
    let organization: Organization

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Header
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColor.primary)
                    Text(organization.name)
                        .font(AppFont.largeTitle)
                    Text("@\(organization.handle)")
                        .font(AppFont.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                    if let bio = organization.bio {
                        Text(bio)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }

                // Stats
                HStack(spacing: AppSpacing.lg) {
                    StatCard(title: "Members", value: "\(organization.memberCount)", icon: "person.2.fill")
                    StatCard(title: "Total Drinks", value: "\(organization.totalOrgDrinks)", icon: "mug.fill")
                }

                // Leaderboard
                LeaderboardCard(
                    title: "Top Performers",
                    entries: organization.leaderboard.prefix(10).map {
                        LeaderboardEntry(
                            name: $0.member.user?.displayName ?? "Unknown",
                            value: $0.drinks,
                            metric: "drinks"
                        )
                    }
                )
            }
            .padding()
        }
        .navigationTitle(organization.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
