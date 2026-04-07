import SwiftUI

struct AddDrinkSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var sessionManager: SessionManager

    @State private var selectedType: DrinkType = .beer
    @State private var customName: String = ""
    @State private var sizeMl: Double = 355
    @State private var alcoholPercentage: Double = 5.0
    @State private var price: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // Drink type
                Section("Type") {
                    Picker("Drink Type", selection: $selectedType) {
                        ForEach(DrinkType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .onChange(of: selectedType) { _, newValue in
                        sizeMl = newValue.defaultSizeMl
                        alcoholPercentage = newValue.defaultAlcoholPercentage
                        if customName.isEmpty || DrinkType.allCases.map(\.rawValue).contains(customName) {
                            customName = newValue.rawValue
                        }
                    }
                }

                // Details
                Section("Details") {
                    TextField("Name", text: $customName)

                    HStack {
                        Text("Size")
                        Spacer()
                        TextField("ml", value: $sizeMl, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("ml")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("ABV")
                        Spacer()
                        TextField("%", value: $alcoholPercentage, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("%")
                            .foregroundStyle(.secondary)
                    }
                }

                // Price
                Section("Price (Optional)") {
                    HStack {
                        Text("$")
                        TextField("0.00", text: $price)
                            .keyboardType(.decimalPad)
                    }
                }

                // Preview
                Section("Summary") {
                    let units = Drink(
                        type: selectedType,
                        name: customName,
                        sizeMl: sizeMl,
                        alcoholPercentage: alcoholPercentage
                    ).standardUnits

                    let cals = Drink.calculateCalories(
                        sizeMl: sizeMl,
                        alcoholPercentage: alcoholPercentage
                    )

                    LabeledContent("Standard Drinks", value: String(format: "%.1f", units))
                    LabeledContent("Calories", value: "\(Int(cals)) cal")
                }
            }
            .navigationTitle("Add Drink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addDrink()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                customName = selectedType.rawValue
            }
        }
    }

    private func addDrink() {
        let drinkPrice = Double(price)
        sessionManager.addDrink(
            type: selectedType,
            name: customName.isEmpty ? selectedType.rawValue : customName,
            sizeMl: sizeMl,
            alcoholPercentage: alcoholPercentage,
            price: drinkPrice,
            venue: sessionManager.activeSession?.venue,
            in: modelContext
        )
    }
}
