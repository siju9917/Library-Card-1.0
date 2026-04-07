import SwiftUI

struct DrinkQuickAddButton: View {
    let drinkType: DrinkType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: drinkType.icon)
                    .font(.title2)
                    .foregroundStyle(.purple)

                Text(drinkType.rawValue)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .frame(width: 72, height: 72)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct DrinkQuickAddGrid: View {
    let onSelect: (DrinkType) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 72, maximum: 90), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(DrinkType.allCases) { type in
                DrinkQuickAddButton(drinkType: type) {
                    onSelect(type)
                }
            }
        }
    }
}
