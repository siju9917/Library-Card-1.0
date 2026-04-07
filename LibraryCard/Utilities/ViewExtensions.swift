import SwiftUI

// MARK: - Keyboard Dismissal

extension View {
    /// Dismiss keyboard when tapping outside of text fields.
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }

    /// Dismiss keyboard when scrolling.
    func dismissKeyboardOnScroll() -> some View {
        self.scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    let isLoading: Bool
    var message: String = "Loading..."

    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                VStack(spacing: AppSpacing.md) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text(message)
                        .font(AppFont.caption)
                        .foregroundStyle(.white)
                }
                .padding(AppSpacing.xxl)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
            }
        }
    }
}

extension View {
    func loadingOverlay(isLoading: Bool, message: String = "Loading...") -> some View {
        self.overlay {
            LoadingOverlay(isLoading: isLoading, message: message)
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(AppColor.textTertiary)

            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.textSecondary)

                Text(subtitle)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .font(AppFont.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColor.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxxl)
    }
}

// MARK: - App Version

enum AppInfo {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    static var displayVersion: String {
        "\(version) (\(build))"
    }
}
