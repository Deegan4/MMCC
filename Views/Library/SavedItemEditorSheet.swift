import SwiftUI
import SwiftData

struct SavedItemEditorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var itemToEdit: SavedItem?

    @State private var itemDescription = ""
    @State private var defaultQty: Decimal = 1
    @State private var defaultPrice: Decimal = 0
    @State private var unit = "ea"
    @State private var category: ItemCategory = .other

    private var isNew: Bool { itemToEdit == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Description (e.g. 12\" Round Piling)", text: $itemDescription)
                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                }

                Section("Defaults") {
                    HStack {
                        Text("Qty")
                        Spacer()
                        TextField("1", value: $defaultQty, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Unit Price")
                        Spacer()
                        TextField("$0", value: $defaultPrice, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    HStack {
                        Text("Unit")
                        Spacer()
                        TextField("ea", text: $unit)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
            }
            .navigationTitle(isNew ? "New Item" : "Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(itemDescription.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    private func loadExisting() {
        guard let item = itemToEdit else { return }
        itemDescription = item.itemDescription
        defaultQty = item.defaultQty
        defaultPrice = item.defaultPrice
        unit = item.unit
        category = item.category
    }

    private func save() {
        if let item = itemToEdit {
            item.itemDescription = itemDescription
            item.defaultQty = defaultQty
            item.defaultPrice = defaultPrice
            item.unit = unit
            item.category = category
        } else {
            let item = SavedItem(
                description: itemDescription.trimmingCharacters(in: .whitespaces),
                qty: defaultQty,
                price: defaultPrice,
                unit: unit,
                category: category
            )
            modelContext.insert(item)
        }
        dismiss()
    }
}
