import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var hasCompletedOnboarding: Bool

    @State private var currentPage = 0
    @State private var displayName = ""
    @State private var selectedSex: BiologicalSex = .preferNotToSay
    @State private var weightKg = ""
    @State private var monthlyBudget = ""
    @State private var weeklyGoal = ""

    private let totalPages = 4

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            progressBar
                .padding(.top, AppSpacing.lg)
                .padding(.horizontal, AppSpacing.xxl)

            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                trackingPage.tag(1)
                profileSetupPage.tag(2)
                readyPage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(AppAnimation.standard, value: currentPage)

            // Navigation buttons
            navigationButtons
                .padding(.horizontal, AppSpacing.xxl)
                .padding(.bottom, AppSpacing.xxl)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index <= currentPage ? AppColor.primary : AppColor.primary.opacity(0.2))
                    .frame(height: 4)
            }
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: AppSpacing.xxl) {
            Spacer()

            Image(systemName: "creditcard.and.123")
                .font(.system(size: 80))
                .foregroundStyle(AppColor.primary)

            VStack(spacing: AppSpacing.md) {
                Text("Welcome to Library Card")
                    .font(AppFont.largeTitle)
                    .multilineTextAlignment(.center)

                Text("Track your nights out with real-time drink logging, spending insights, and Strava-style session recaps.")
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxl)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome to Library Card. Track your nights out with real-time drink logging and spending insights.")
    }

    private var trackingPage: some View {
        VStack(spacing: AppSpacing.xxl) {
            Spacer()

            VStack(spacing: AppSpacing.xl) {
                OnboardingFeature(
                    icon: "play.circle.fill",
                    title: "Session Tracking",
                    description: "Start a session when you go out. Log drinks with one tap."
                )
                OnboardingFeature(
                    icon: "speedometer",
                    title: "Live Pace",
                    description: "See your drinks per hour, spending, and estimated BAC in real time."
                )
                OnboardingFeature(
                    icon: "chart.bar.fill",
                    title: "Rich Statistics",
                    description: "Weekly trends, drink type breakdowns, venue rankings, and more."
                )
                OnboardingFeature(
                    icon: "creditcard.fill",
                    title: "Card Integration",
                    description: "Connect a payment card to auto-detect purchases at bars."
                )
            }
            .padding(.horizontal, AppSpacing.xxl)

            Spacer()
        }
    }

    private var profileSetupPage: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                VStack(spacing: AppSpacing.sm) {
                    Text("Set Up Your Profile")
                        .font(AppFont.title)

                    Text("This helps us personalize your experience. All fields are optional.")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppSpacing.xxl)

                VStack(spacing: AppSpacing.lg) {
                    OnboardingTextField(
                        title: "Display Name",
                        placeholder: "What should we call you?",
                        text: $displayName
                    )

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Biological Sex")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.textSecondary)
                        Picker("Biological Sex", selection: $selectedSex) {
                            ForEach(BiologicalSex.allCases) { sex in
                                Text(sex.rawValue).tag(sex)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    OnboardingTextField(
                        title: "Weight (kg)",
                        placeholder: "For BAC estimation",
                        text: $weightKg,
                        keyboardType: .decimalPad
                    )

                    OnboardingTextField(
                        title: "Monthly Budget ($)",
                        placeholder: "Optional spending limit",
                        text: $monthlyBudget,
                        keyboardType: .decimalPad
                    )

                    OnboardingTextField(
                        title: "Weekly Drink Goal",
                        placeholder: "Target max drinks per week",
                        text: $weeklyGoal,
                        keyboardType: .numberPad
                    )
                }
                .padding(.horizontal, AppSpacing.xxl)

                Text("Weight and sex are used for BAC estimation only. This is not medical advice.")
                    .font(AppFont.caption2)
                    .foregroundStyle(AppColor.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxl)
            }
        }
    }

    private var readyPage: some View {
        VStack(spacing: AppSpacing.xxl) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppColor.success)

            VStack(spacing: AppSpacing.md) {
                Text("You're All Set!")
                    .font(AppFont.largeTitle)

                Text("Start your first session whenever you're ready. Tap the Session tab to begin tracking.")
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxl)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Setup complete. You're all set to start tracking.")
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        HStack {
            if currentPage > 0 {
                Button("Back") {
                    withAnimation { currentPage -= 1 }
                }
                .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            if currentPage < totalPages - 1 {
                Button {
                    withAnimation { currentPage += 1 }
                } label: {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColor.primary)
                }
            } else {
                Button {
                    completeOnboarding()
                } label: {
                    Text("Get Started")
                        .primaryButtonStyle()
                }
            }
        }
    }

    // MARK: - Actions

    private func completeOnboarding() {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let user = User(
            displayName: name.isEmpty ? "User" : name,
            weightKg: Double(weightKg),
            biologicalSex: selectedSex,
            monthlyBudget: Double(monthlyBudget),
            weeklyDrinkGoal: Int(weeklyGoal)
        )
        modelContext.insert(user)
        try? modelContext.save()

        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Supporting Views

struct OnboardingFeature: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(AppColor.primary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(title)
                    .font(AppFont.headline)
                Text(description)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

struct OnboardingTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(.roundedBorder)
        }
    }
}
