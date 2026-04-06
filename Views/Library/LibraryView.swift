import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedItem.itemDescription) private var allItems: [SavedItem]
    @Query(sort: \JobTemplate.name) private var templates: [JobTemplate]
    @Query(sort: \Customer.name) private var customers: [Customer]

    @State private var searchText = ""
    @State private var selectedCategory: ItemCategory?
    @Environment(ProTierService.self) private var proTierService: ProTierService?
    @State private var showingEditor = false
    @State private var showingPaywall = false
    @State private var itemToEdit: SavedItem?
    @State private var showingTemplateEditor = false
    @State private var showingPriceList = false

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
                savedItemsSection
                templatesSection
                customersSection
            }
            .searchable(text: $searchText, prompt: "Search items...")
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 16) {
                        Button {
                            showingPriceList = true
                        } label: {
                            Image(systemName: "dollarsign.arrow.trianglehead.counterclockwise.rotate.90")
                        }
                        .accessibilityLabel("Price List")

                        Button {
                            if proTierService?.canAddSavedItem() ?? true {
                                itemToEdit = nil
                                showingEditor = true
                            } else {
                                showingPaywall = true
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .navigationDestination(for: JobTemplate.self) { template in
                TemplateDetailView(template: template)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingEditor) {
                SavedItemEditorSheet(itemToEdit: itemToEdit)
            }
            .sheet(isPresented: $showingTemplateEditor) {
                TemplateEditorSheet()
            }
            .sheet(isPresented: $showingPriceList) {
                PriceListView()
            }
        }
    }

    // MARK: - Saved Items

    private var savedItemsSection: some View {
        Section {
            categoryFilterRow
            if filteredItems.isEmpty {
                ContentUnavailableView {
                    Label("No Items", systemImage: "tray")
                } description: {
                    Text(searchText.isEmpty
                        ? "Tap + to add materials and labor you use often."
                        : "No items match your search.")
                }
            } else {
                ForEach(filteredItems) { item in
                    SavedItemRow(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            itemToEdit = item
                            showingEditor = true
                        }
                }
                .onDelete(perform: deleteItems)
            }
        } header: {
            Text("Saved Items (\(filteredItems.count))")
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

    // MARK: - Templates

    private var templatesSection: some View {
        Section {
            ForEach(templates) { template in
                NavigationLink(value: template) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name).font(.body.bold())
                            Text("\(template.sortedSections.count) sections · used \(template.usageCount)×")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(template.estimatedTotal.formatted(.currency(code: "USD")))
                            .font(.subheadline)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions(edge: .leading) {
                    Button("Duplicate") {
                        template.duplicate(in: modelContext)
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .trailing) {
                    if !template.isSystemTemplate {
                        Button("Delete", role: .destructive) {
                            modelContext.delete(template)
                        }
                    }
                }
            }

            Button {
                showingTemplateEditor = true
            } label: {
                Label("New Template", systemImage: "plus.circle")
                    .font(.subheadline)
            }
        } header: {
            Text("Templates (\(templates.count))")
        }
    }

    // MARK: - Customers

    private var customersSection: some View {
        Section("Customers (\(customers.count))") {
            ForEach(customers) { customer in
                VStack(alignment: .leading) {
                    Text(customer.name).font(.body.bold())
                    if !customer.address.isEmpty {
                        Text(customer.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredItems[index])
        }
    }
}

// MARK: - Supporting Views

struct SavedItemRow: View {
    let item: SavedItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.itemDescription).font(.body)
            HStack {
                Text(item.category.displayName)
                Spacer()
                Text(item.defaultPrice.formatted(.currency(code: "USD")))
                Text("/ \(item.unit)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if item.usageCount > 0 {
                Text("Used \(item.usageCount) time\(item.usageCount == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var tint: Color = .accentColor
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundStyle(isSelected ? .white : .secondary)
                .background(
                    isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(.fill.tertiary),
                    in: .capsule
                )
        }
        .buttonStyle(.plain)
    }
}
