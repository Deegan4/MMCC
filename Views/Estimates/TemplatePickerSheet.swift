import SwiftUI

struct TemplatePickerSheet: View {
    let templates: [JobTemplate]
    let onSelect: (JobTemplate) -> Void
    let onBlank: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingTemplateEditor = false

    private var systemTemplates: [JobTemplate] {
        templates.filter { $0.isSystemTemplate }
    }

    private var customTemplates: [JobTemplate] {
        templates.filter { !$0.isSystemTemplate }
    }

    var body: some View {
        NavigationStack {
            List {
                if !systemTemplates.isEmpty {
                    Section("HVAC Templates") {
                        ForEach(systemTemplates) { template in
                            templateRow(template)
                        }
                    }
                }

                if !customTemplates.isEmpty {
                    Section("Custom Templates") {
                        ForEach(customTemplates) { template in
                            templateRow(template)
                        }
                    }
                }

                Section {
                    Button {
                        onBlank()
                        dismiss()
                    } label: {
                        Label("Blank Proposal", systemImage: "doc")
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)

                    Button {
                        showingTemplateEditor = true
                    } label: {
                        Label("Create New Template", systemImage: "plus.circle")
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("New Proposal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingTemplateEditor) {
                TemplateEditorSheet()
            }
        }
    }

    private func templateRow(_ template: JobTemplate) -> some View {
        Button {
            onSelect(template)
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.body.bold())
                        .foregroundStyle(.primary)
                    Text("\(template.sortedSections.count) sections · used \(template.usageCount)×")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !template.sortedSections.isEmpty {
                        Text(template.sortedSections.prefix(3).map(\.name).joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(template.estimatedTotal.formatted(.currency(code: "USD")))
                        .font(.subheadline.bold())
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                    Text("est.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
