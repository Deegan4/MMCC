import SwiftUI
import SwiftData

struct PriceListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SavedItem.itemDescription) private var allItems: [SavedItem]

    @State private var searchText = ""
    @State private var selectedCategory: ItemCategory?
    @State private var editedPrices: [UUID: Decimal] = [:]
    @State private var showingSaveConfirmation = false

    private var filteredItems: [SavedItem] {
        allItems.filter { item in
            let matchesCategory = selectedCategory == nil || item.category == selectedCategory
            let matchesSearch = searchText.isEmpty
                || item.itemDescription.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    private var groupedItems: [(ItemCategory, [SavedItem])] {
        let grouped = Dictionary(grouping: filteredItems, by: \.category)
        return ItemCategory.allCases.compactMap { cat in
            guard let items = grouped[cat], !items.isEmpty else { return nil }
            return (cat, items.sorted { $0.itemDescription < $1.itemDescription })
        }
    }

    private var hasChanges: Bool { !editedPrices.isEmpty }

    var body: some View {
        NavigationStack {
            List {
                if hasChanges {
                    changesSummary
                }

                ForEach(groupedItems, id: \.0) { category, items in
                    Section(category.displayName) {
                        ForEach(items) { item in
                            PriceRow(
                                item: item,
                                editedPrice: Binding(
                                    get: { editedPrices[item.id] ?? item.defaultPrice },
                                    set: { newPrice in
                                        if newPrice == item.defaultPrice {
                                            editedPrices.removeValue(forKey: item.id)
                                        } else {
                                            editedPrices[item.id] = newPrice
                                        }
                                    }
                                )
                            )
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search materials...")
            .navigationTitle("Price List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save \(hasChanges ? "(\(editedPrices.count))" : "")") {
                        applyChanges()
                    }
                    .bold()
                    .disabled(!hasChanges)
                }
            }
            .alert("Prices Updated", isPresented: $showingSaveConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                Text("\(editedPrices.count) item price\(editedPrices.count == 1 ? "" : "s") updated. Changes apply to new proposals only — existing proposals are unchanged.")
            }
        }
    }

    private var changesSummary: some View {
        Section {
            HStack {
                Image(systemName: "pencil.circle.fill")
                    .foregroundStyle(.orange)
                Text("\(editedPrices.count) price\(editedPrices.count == 1 ? "" : "s") changed")
                    .font(.subheadline.bold())
                Spacer()
                Button("Reset All") {
                    editedPrices.removeAll()
                }
                .font(.caption)
                .foregroundStyle(.red)
            }
        }
    }

    private func applyChanges() {
        for (itemID, newPrice) in editedPrices {
            if let item = allItems.first(where: { $0.id == itemID }) {
                item.defaultPrice = newPrice
            }
        }
        showingSaveConfirmation = true
    }
}

// MARK: - Price Row

private struct PriceRow: View {
    let item: SavedItem
    @Binding var editedPrice: Decimal

    private var isModified: Bool { editedPrice != item.defaultPrice }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.itemDescription)
                    .font(.subheadline)
                    .lineLimit(2)
                Text("\(item.unit)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isModified {
                Text(item.defaultPrice.formatted(.currency(code: "USD")))
                    .font(.caption)
                    .strikethrough()
                    .foregroundStyle(.secondary)
            }

            TextField("$0", value: $editedPrice, format: .currency(code: "USD"))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
                .textFieldStyle(.roundedBorder)
                .foregroundStyle(isModified ? .orange : .primary)
                .fontWeight(isModified ? .bold : .regular)
        }
        .padding(.vertical, 2)
    }
}
