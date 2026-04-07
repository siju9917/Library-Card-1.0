import SwiftUI

// MARK: - Colors

enum AppColor {
    static let primary = Color.purple
    static let secondary = Color.purple.opacity(0.7)
    static let accent = Color.purple

    static let success = Color.green
    static let warning = Color.yellow
    static let danger = Color.red
    static let info = Color.blue

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color(uiColor: .tertiaryLabel)

    static let backgroundPrimary = Color(uiColor: .systemBackground)
    static let backgroundSecondary = Color(uiColor: .secondarySystemBackground)
    static let backgroundGrouped = Color(uiColor: .systemGroupedBackground)

    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)

    // BAC severity colors
    static let bacSafe = Color.green
    static let bacCaution = Color.yellow
    static let bacDanger = Color.red

    static func bacColor(for bac: Double) -> Color {
        if bac < 0.04 { return bacSafe }
        if bac < 0.08 { return bacCaution }
        return bacDanger
    }

    // Chart palette
    static let chartPalette: [Color] = [
        .purple, .blue, .green, .orange, .pink, .cyan, .yellow, .red, .mint
    ]
}

// MARK: - Typography

enum AppFont {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title2.weight(.bold)
    static let headline = Font.headline
    static let subheadline = Font.subheadline
    static let body = Font.body
    static let caption = Font.caption
    static let caption2 = Font.caption2

    static let timerDisplay = Font.system(size: 48, weight: .light, design: .monospaced)
    static let statValue = Font.title2.weight(.bold)
    static let statLabel = Font.caption
    static let monoDigit = Font.subheadline.monospacedDigit()
}

// MARK: - Spacing

enum AppSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Corner Radius

enum AppRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let pill: CGFloat = 999
}

// MARK: - Animation

enum AppAnimation {
    static let standard = Animation.easeInOut(duration: 0.25)
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let slow = Animation.easeInOut(duration: 0.5)
}

// MARK: - View Modifiers

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.lg)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
    }
}

struct PrimaryButtonModifier: ViewModifier {
    var isDisabled: Bool = false

    func body(content: Content) -> some View {
        content
            .font(AppFont.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isDisabled ? AppColor.primary.opacity(0.4) : AppColor.primary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
    }
}

struct DestructiveButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppFont.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColor.danger.opacity(0.9))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }

    func primaryButtonStyle(isDisabled: Bool = false) -> some View {
        modifier(PrimaryButtonModifier(isDisabled: isDisabled))
    }

    func destructiveButtonStyle() -> some View {
        modifier(DestructiveButtonModifier())
    }
}
