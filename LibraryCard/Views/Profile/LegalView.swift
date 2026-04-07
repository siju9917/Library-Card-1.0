import SwiftUI

struct LegalView: View {
    var body: some View {
        List {
            NavigationLink("Privacy Policy") {
                PrivacyPolicyView()
            }
            NavigationLink("Terms of Service") {
                TermsOfServiceView()
            }
            NavigationLink("Account & Data") {
                AccountManagementView()
            }
        }
        .navigationTitle("Legal")
    }
}

// MARK: - Privacy Policy

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Privacy Policy")
                    .font(AppFont.largeTitle)

                Text("Last updated: \(Date(), format: .dateTime.month(.wide).year())")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiary)

                Group {
                    sectionHeader("Information We Collect")
                    sectionBody("""
                    Library Card collects the following information to provide our services:

                    - **Account Information**: Display name, username, and email address when you sign in with Apple.
                    - **Drinking Session Data**: Drink types, quantities, timestamps, and session duration that you voluntarily log.
                    - **Location Data**: Venue check-ins and bar route tracking, only when you explicitly check in or enable location services.
                    - **Photos**: Session photos you choose to capture and share, stored on-device and shared only with your chosen audience.
                    - **Social Data**: Friend connections, organization memberships, messages, and showdown participation.
                    - **Health-Related Data**: Weight and biological sex, used solely for BAC estimation. This data stays on your device.
                    """)

                    sectionHeader("How We Use Your Information")
                    sectionBody("""
                    - To provide session tracking, statistics, and Wrapped recaps.
                    - To enable social features like leaderboards, showdowns, and friend activity.
                    - To send notifications you've opted into (session reminders, morning-after messages, safety alerts).
                    - To improve app functionality and fix bugs.
                    """)

                    sectionHeader("Data Storage & Security")
                    sectionBody("""
                    - Session data is stored locally on your device using Apple's SwiftData framework.
                    - Authentication credentials are stored in the iOS Keychain.
                    - We use industry-standard encryption for data in transit (TLS 1.3).
                    - We do not sell your personal data to third parties.
                    """)

                    sectionHeader("Your Rights")
                    sectionBody("""
                    - **Access**: You can export all your data at any time from Settings > Account & Data > Export My Data.
                    - **Deletion**: You can delete your account and all associated data from Settings > Account & Data > Delete Account.
                    - **Correction**: You can update your profile information at any time.
                    - **Portability**: Your exported data is provided in a standard JSON format.
                    """)

                    sectionHeader("Age Requirement")
                    sectionBody("Library Card is intended for users aged 21 and older. We require age verification during account creation.")

                    sectionHeader("Contact")
                    sectionBody("For privacy questions, contact us at privacy@librarycard.app")
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(AppFont.headline)
            .padding(.top, AppSpacing.sm)
    }

    private func sectionBody(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(AppFont.body)
            .foregroundStyle(AppColor.textSecondary)
    }
}

// MARK: - Terms of Service

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Terms of Service")
                    .font(AppFont.largeTitle)

                Text("Last updated: \(Date(), format: .dateTime.month(.wide).year())")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiary)

                Group {
                    sectionHeader("Acceptance of Terms")
                    sectionBody("By using Library Card, you agree to these Terms of Service. If you do not agree, do not use the app.")

                    sectionHeader("Eligibility")
                    sectionBody("You must be at least 21 years of age to use Library Card. By creating an account, you confirm that you meet this requirement.")

                    sectionHeader("Responsible Use")
                    sectionBody("""
                    Library Card is a social tool for tracking and sharing your experiences. You agree to:

                    - Use the app responsibly and never drive under the influence of alcohol.
                    - Not rely on BAC estimates for safety decisions. These are rough calculations and not medically accurate.
                    - Not use the app to harass, stalk, or harm other users.
                    - Not send abusive, threatening, or inappropriate content through DMs or photos.
                    - Respect other users' privacy and consent.
                    """)

                    sectionHeader("User Content")
                    sectionBody("You retain ownership of photos and content you post. By sharing content, you grant Library Card a non-exclusive license to display it to your chosen audience within the app.")

                    sectionHeader("Safety Features")
                    sectionBody("The SOS feature is a convenience tool to alert friends. It is not a substitute for calling 911 or emergency services. In an emergency, always call local emergency services directly.")

                    sectionHeader("Account Termination")
                    sectionBody("We reserve the right to suspend or terminate accounts that violate these terms. You can delete your account at any time from Settings.")

                    sectionHeader("Disclaimer")
                    sectionBody("Library Card is provided \"as is\" without warranties of any kind. We are not responsible for decisions made based on data shown in the app, including BAC estimates, drink counts, or any health-related information.")

                    sectionHeader("Contact")
                    sectionBody("For questions about these terms, contact us at legal@librarycard.app")
                }
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(AppFont.headline)
            .padding(.top, AppSpacing.sm)
    }

    private func sectionBody(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(AppFont.body)
            .foregroundStyle(AppColor.textSecondary)
    }
}

// MARK: - Account Management (Deletion + Export)

struct AccountManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showDeleteConfirmation = false
    @State private var showExportSheet = false
    @State private var exportedData: String?
    @State private var isExporting = false
    @State private var isDeleting = false

    var body: some View {
        List {
            Section("Data Export") {
                Button {
                    exportData()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export My Data")
                        Spacer()
                        if isExporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isExporting)

                Text("Export all your sessions, drinks, and profile data as JSON.")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiary)
            }

            Section("Danger Zone") {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Delete My Account")
                        Spacer()
                        if isDeleting {
                            ProgressView()
                        }
                    }
                    .foregroundStyle(AppColor.danger)
                }
                .disabled(isDeleting)

                Text("This will permanently delete your account, all sessions, drinks, photos, messages, and social connections. This action cannot be undone.")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiary)
            }
        }
        .navigationTitle("Account & Data")
        .confirmationDialog(
            "Delete Account?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) {
                deleteAccount()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all data. This cannot be undone.")
        }
        .sheet(isPresented: $showExportSheet) {
            if let data = exportedData {
                ExportShareSheet(exportData: data)
            }
        }
    }

    private func exportData() {
        isExporting = true
        Task {
            let data = DataExportService.exportAll(context: modelContext)
            await MainActor.run {
                exportedData = data
                isExporting = false
                showExportSheet = true
            }
        }
    }

    private func deleteAccount() {
        isDeleting = true
        DataExportService.deleteAllData(context: modelContext)
        hasCompletedOnboarding = false
        isDeleting = false
    }
}

struct ExportShareSheet: View {
    let exportData: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(exportData)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Exported Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    ShareLink(item: exportData) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}
