import SwiftUI
import SwiftData

struct SavedItemPickerSheet: View {
    @Query(sort: \SavedItem.itemDescription) private var allItems: [SavedItem]
    @Environment(\.dismiss) private var dismiss

    let section: ProposalSection

    @State private var searchText = ""
    @State private var selectedCategory: ItemCategory?

    private var filteredItems: [SavedItem] {
        allItems.filter { item in
            let matchesCategory = selectedCategory == nil || item.category == selectedCategory
            let matchesSearch = searchText.isEmpty
                || item.itemDescription.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if allItems.isEmpty {
                    ContentUnavailableView {
                        Label("No Saved Items", systemImage: "tray")
                    } description: {
                        Text("Add items in the Library tab first.")
                    }
                } else {
                    categoryFilterRow
                    ForEach(filteredItems) { item in
                        Button {
                            addToSection(item)
                        } label: {
                            SavedItemRow(item: item)
                        }
                        .tint(.primary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search saved items...")
            .navigationTitle("Add from Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(ItemCategory.allCases) { cat in
                    FilterChip(title: cat.displayName, isSelected: selectedCategory == cat) {
                        selectedCategory = (selectedCategory == cat) ? nil : cat
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    private func addToSection(_ savedItem: SavedItem) {
        let lineItem = ProposalLineItem(
            description: savedItem.itemDescription,
            quantity: savedItem.defaultQty,
            unitPrice: savedItem.defaultPrice,
            unit: savedItem.unit
        )
        lineItem.savedItemID = savedItem.id
        lineItem.sortOrder = (section.lineItems ?? []).count
        if section.lineItems == nil { section.lineItems = [] }
        section.lineItems?.append(lineItem)
        savedItem.recordUsage()
    }
}
