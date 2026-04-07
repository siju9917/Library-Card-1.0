import SwiftUI

struct DrinkQuickAddButton: View {
    let drinkType: DrinkType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: drinkType.icon)
                    .font(.title2)
                    .foregroundStyle(AppColor.primary)

                Text(drinkType.rawValue)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textPrimary)
            }
            .frame(width: 72, height: 72)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add \(drinkType.rawValue)")
        .accessibilityHint("Quick-add a \(drinkType.rawValue) with default size and ABV")
    }
}

struct DrinkQuickAddGrid: View {
    let onSelect: (DrinkType) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 72, maximum: 90), spacing: AppSpacing.md)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.md) {
            ForEach(DrinkType.allCases) { type in
                DrinkQuickAddButton(drinkType: type) {
                    onSelect(type)
                }
            }
        }
    }
}
