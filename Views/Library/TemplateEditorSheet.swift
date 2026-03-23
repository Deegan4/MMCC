import SwiftUI
import SwiftData

struct TemplateEditorSheet: View {
    var templateToEdit: JobTemplate?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var defaultNotes = ""
    @State private var defaultTerms = ""
    @State private var defaultMarkup: Decimal = 0
    @State private var defaultTaxRate: Decimal = 0
    @State private var editorSections: [EditorSection] = []

    private var isNew: Bool { templateToEdit == nil }

    var body: some View {
        NavigationStack {
            Form {
                templateInfoSection
                ForEach($editorSections) { $section in
                    editorSectionView(section: $section)
                }
                addSectionButton
                defaultsSection
                notesSection
            }
            .navigationTitle(isNew ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    // MARK: - Sections

    private var templateInfoSection: some View {
        Section("Template Info") {
            TextField("Template Name", text: $name)
                .font(.headline)
        }
    }

    private func editorSectionView(section: Binding<EditorSection>) -> some View {
        Section {
            ForEach(section.items) { $item in
                editorItemRow(item: $item)
            }
            .onDelete { offsets in
                section.wrappedValue.items.remove(atOffsets: offsets)
                reindexItems(in: &section.wrappedValue)
            }

            Button {
                let newItem = EditorItem(sortOrder: section.wrappedValue.items.count)
                section.wrappedValue.items.append(newItem)
            } label: {
                Label("Add Item", systemImage: "plus")
                    .font(.caption)
            }

            HStack {
                Spacer()
                Text("Section Total: \(sectionTotal(section.wrappedValue).formatted(.currency(code: "USD")))")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        } header: {
            HStack {
                Text(section.wrappedValue.name)
                Spacer()
                Button(role: .destructive) {
                    if let idx = editorSections.firstIndex(where: { $0.id == section.wrappedValue.id }) {
                        editorSections.remove(at: idx)
                        reindexSections()
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
            }
        }
    }

    private func editorItemRow(item: Binding<EditorItem>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Description", text: item.itemDescription)
                .font(.body)

            HStack {
                HStack(spacing: 4) {
                    Text("Qty")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("1", value: item.defaultQty, format: .number)
                        .keyboardType(.decimalPad)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 4) {
                    Text("@")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("$0", value: item.defaultPrice, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                }

                TextField("ea", text: item.unit)
                    .frame(width: 40)
                    .textFieldStyle(.roundedBorder)

                Spacer()

                Text((item.wrappedValue.defaultQty * item.wrappedValue.defaultPrice).formatted(.currency(code: "USD")))
                    .font(.subheadline.bold())
                    .monospacedDigit()
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }

    private var addSectionButton: some View {
        Section {
            Menu {
                ForEach(MarineSection.allCases) { section in
                    Button(section.displayName) {
                        let newSection = EditorSection(
                            name: section.displayName,
                            sortOrder: editorSections.count
                        )
                        editorSections.append(newSection)
                    }
                }
            } label: {
                Label("Add Section", systemImage: "plus.circle")
            }
        }
    }

    private var defaultsSection: some View {
        Section("Defaults") {
            HStack {
                Text("Markup %")
                Spacer()
                TextField("0", value: $defaultMarkup, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
            }
            HStack {
                Text("Tax %")
                Spacer()
                TextField("0", value: $defaultTaxRate, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
            }
        }
    }

    private var notesSection: some View {
        Section("Notes & Terms") {
            VStack(alignment: .leading) {
                Text("Default Notes").font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $defaultNotes)
                    .frame(minHeight: 60)
            }
            VStack(alignment: .leading) {
                Text("Default Terms").font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $defaultTerms)
                    .frame(minHeight: 60)
            }
        }
    }

    // MARK: - Helpers

    private func sectionTotal(_ section: EditorSection) -> Decimal {
        section.items.reduce(.zero) { $0 + $1.defaultQty * $1.defaultPrice }
    }

    private func reindexItems(in section: inout EditorSection) {
        for i in section.items.indices {
            section.items[i].sortOrder = i
        }
    }

    private func reindexSections() {
        for i in editorSections.indices {
            editorSections[i].sortOrder = i
        }
    }

    // MARK: - Load / Save

    private func loadExisting() {
        guard let template = templateToEdit else { return }
        name = template.name
        defaultNotes = template.defaultNotes
        defaultTerms = template.defaultTerms
        defaultMarkup = template.defaultMarkup
        defaultTaxRate = template.defaultTaxRate
        editorSections = template.sortedSections.map { section in
            EditorSection(
                name: section.name,
                sortOrder: section.sortOrder,
                items: section.sortedItems.map { item in
                    EditorItem(
                        itemDescription: item.itemDescription,
                        defaultQty: item.defaultQty,
                        defaultPrice: item.defaultPrice,
                        unit: item.unit,
                        sortOrder: item.sortOrder
                    )
                }
            )
        }
    }

    private func save() {
        if let existing = templateToEdit {
            existing.name = name
            existing.defaultNotes = defaultNotes
            existing.defaultTerms = defaultTerms
            existing.defaultMarkup = defaultMarkup
            existing.defaultTaxRate = defaultTaxRate
            // Delete old sections (cascade deletes items)
            for old in existing.sections ?? [] {
                modelContext.delete(old)
            }
            existing.sections = []
            // Rebuild from editor state
            for es in editorSections {
                let section = TemplateSection(name: es.name, sortOrder: es.sortOrder)
                for ei in es.items {
                    let item = TemplateItem(description: ei.itemDescription, qty: ei.defaultQty, price: ei.defaultPrice, unit: ei.unit)
                    item.sortOrder = ei.sortOrder
                    if section.items == nil { section.items = [] }
                    section.items?.append(item)
                }
                existing.sections?.append(section)
            }
        } else {
            let template = JobTemplate(name: name)
            template.defaultNotes = defaultNotes
            template.defaultTerms = defaultTerms
            template.defaultMarkup = defaultMarkup
            template.defaultTaxRate = defaultTaxRate
            template.isSystemTemplate = false
            for es in editorSections {
                let section = TemplateSection(name: es.name, sortOrder: es.sortOrder)
                for ei in es.items {
                    let item = TemplateItem(description: ei.itemDescription, qty: ei.defaultQty, price: ei.defaultPrice, unit: ei.unit)
                    item.sortOrder = ei.sortOrder
                    if section.items == nil { section.items = [] }
                    section.items?.append(item)
                }
                if template.sections == nil { template.sections = [] }
                template.sections?.append(section)
            }
            modelContext.insert(template)
        }
        dismiss()
    }
}

// MARK: - Editor Types

struct EditorSection: Identifiable {
    let id = UUID()
    var name: String
    var sortOrder: Int
    var items: [EditorItem] = []
}

struct EditorItem: Identifiable {
    let id = UUID()
    var itemDescription: String = ""
    var defaultQty: Decimal = 1
    var defaultPrice: Decimal = 0
    var unit: String = "ea"
    var sortOrder: Int = 0
}
