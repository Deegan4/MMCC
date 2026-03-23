import SwiftUI
import SwiftData

struct SaveAsTemplateSheet: View {
    let proposal: Proposal
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var templateName: String = ""
    @State private var includeNotes = true
    @State private var includeTerms = true
    @State private var includeDefaults = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Template Name") {
                    TextField("Template Name", text: $templateName)
                        .font(.headline)
                }

                Section("Include") {
                    Toggle("Notes", isOn: $includeNotes)
                    Toggle("Terms", isOn: $includeTerms)
                    Toggle("Markup & Tax Defaults", isOn: $includeDefaults)
                }

                Section("Preview") {
                    HStack {
                        Text("Sections")
                        Spacer()
                        Text("\(proposal.sortedSections.count)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Line Items")
                        Spacer()
                        let itemCount = proposal.sortedSections.reduce(0) { $0 + $1.sortedLineItems.count }
                        Text("\(itemCount)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Estimated Total")
                        Spacer()
                        Text(proposal.grandTotal.formatted(.currency(code: "USD")))
                            .font(.subheadline.bold())
                            .monospacedDigit()
                    }
                }
            }
            .navigationTitle("Save as Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTemplate() }
                        .disabled(templateName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                templateName = proposal.title
            }
        }
    }

    private func saveTemplate() {
        let template = JobTemplate(name: templateName)
        template.isSystemTemplate = false
        template.defaultNotes = includeNotes ? proposal.notes : ""
        template.defaultTerms = includeTerms ? proposal.terms : ""
        template.defaultMarkup = includeDefaults ? proposal.markup : 0
        template.defaultTaxRate = includeDefaults ? proposal.taxRate : 0

        for section in proposal.sortedSections {
            let templateSection = TemplateSection(name: section.name, sortOrder: section.sortOrder)
            for item in section.sortedLineItems {
                let templateItem = TemplateItem(
                    description: item.itemDescription,
                    qty: item.quantity,
                    price: item.unitPrice,
                    unit: item.unit
                )
                templateItem.sortOrder = item.sortOrder
                if templateSection.items == nil { templateSection.items = [] }
                templateSection.items?.append(templateItem)
            }
            if template.sections == nil { template.sections = [] }
            template.sections?.append(templateSection)
        }

        modelContext.insert(template)
        dismiss()
    }
}
