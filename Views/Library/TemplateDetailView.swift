import SwiftUI
import SwiftData

struct TemplateDetailView: View {
    @Bindable var template: JobTemplate
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditor = false
    @State private var showingDeleteConfirm = false

    var body: some View {
        Form {
            headerSection
            ForEach(template.sortedSections) { section in
                templateSectionView(section)
            }
            totalsSection
            if !template.defaultNotes.isEmpty || !template.defaultTerms.isEmpty {
                notesSection
            }
        }
        .navigationTitle(template.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit Template", systemImage: "pencil") {
                        showingEditor = true
                    }
                    Button("Duplicate", systemImage: "doc.on.doc") {
                        template.duplicate(in: modelContext)
                    }
                    if !template.isSystemTemplate {
                        Divider()
                        Button("Delete Template", systemImage: "trash", role: .destructive) {
                            showingDeleteConfirm = true
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            TemplateEditorSheet(templateToEdit: template)
        }
        .alert("Delete Template?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                modelContext.delete(template)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \"\(template.name)\" and all its sections. This cannot be undone.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                    HStack(spacing: 8) {
                        Label(
                            template.isSystemTemplate ? "System" : "Custom",
                            systemImage: template.isSystemTemplate ? "building.2" : "person"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Text("·")
                            .foregroundStyle(.tertiary)

                        Text("Used \(template.usageCount)×")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(template.estimatedTotal.formatted(.currency(code: "USD")))
                    .font(.title3.bold())
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Template Section

    private func templateSectionView(_ section: TemplateSection) -> some View {
        Section(section.name) {
            ForEach(section.sortedItems) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.itemDescription)
                            .font(.body)
                        Text("\(item.defaultQty.formatted(.number)) \(item.unit) @ \(item.defaultPrice.formatted(.currency(code: "USD")))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text((item.defaultQty * item.defaultPrice).formatted(.currency(code: "USD")))
                        .font(.subheadline.bold())
                        .monospacedDigit()
                }
                .padding(.vertical, 2)
            }

            HStack {
                Spacer()
                Text("Section Total: \(section.sectionSubtotal.formatted(.currency(code: "USD")))")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Totals

    private var totalsSection: some View {
        Section("Estimated Totals") {
            HStack {
                Text("Subtotal")
                Spacer()
                Text(template.estimatedSubtotal.formatted(.currency(code: "USD")))
            }
            if template.defaultMarkup > 0 {
                HStack {
                    Text("Markup (\(template.defaultMarkup.formatted(.number))%)")
                    Spacer()
                    let markupAmt = template.estimatedSubtotal * (template.defaultMarkup / 100)
                    Text(markupAmt.formatted(.currency(code: "USD")))
                        .foregroundStyle(.secondary)
                }
            }
            if template.defaultTaxRate > 0 {
                HStack {
                    Text("Tax (\(template.defaultTaxRate.formatted(.number))%)")
                    Spacer()
                    let afterMarkup = template.estimatedSubtotal + (template.defaultMarkup > 0 ? template.estimatedSubtotal * (template.defaultMarkup / 100) : 0)
                    let taxAmt = afterMarkup * (template.defaultTaxRate / 100)
                    Text(taxAmt.formatted(.currency(code: "USD")))
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                Text("Estimated Total")
                    .font(.headline)
                Spacer()
                Text(template.estimatedTotal.formatted(.currency(code: "USD")))
                    .font(.headline)
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        Section("Notes & Terms") {
            if !template.defaultNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes").font(.caption).foregroundStyle(.secondary)
                    Text(template.defaultNotes).font(.body)
                }
            }
            if !template.defaultTerms.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Terms").font(.caption).foregroundStyle(.secondary)
                    Text(template.defaultTerms).font(.body)
                }
            }
        }
    }
}
