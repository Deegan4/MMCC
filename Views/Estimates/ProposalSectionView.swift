import SwiftUI
import SwiftData

struct ProposalSectionView: View {
    @Bindable var section: ProposalSection
    let proposal: Proposal
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddItem = false
    @State private var showingLibraryPicker = false

    var body: some View {
        Section(section.name) {
            // Permit status row
            PermitStatusRow(section: section)

            ForEach(section.sortedLineItems) { item in
                LineItemRow(item: item)
            }
            .onDelete(perform: deleteItems)

            HStack(spacing: 16) {
                Button {
                    addLineItem()
                } label: {
                    Label("Add Line Item", systemImage: "plus")
                        .font(.caption)
                }
                Button {
                    showingLibraryPicker = true
                } label: {
                    Label("From Library", systemImage: "tray.and.arrow.down")
                        .font(.caption)
                }
            }

            HStack {
                Spacer()
                Text("Section Total: \(section.subtotal.formatted(.currency(code: "USD")))")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showingLibraryPicker) {
            SavedItemPickerSheet(section: section)
        }
    }

    private func addLineItem() {
        let item = ProposalLineItem()
        item.sortOrder = (section.lineItems ?? []).count
        if section.lineItems == nil { section.lineItems = [] }
        section.lineItems?.append(item)
    }

    private func deleteItems(at offsets: IndexSet) {
        let sorted = section.sortedLineItems
        for index in offsets {
            modelContext.delete(sorted[index])
        }
    }
}

// MARK: - Permit Status

struct PermitStatusRow: View {
    @Bindable var section: ProposalSection
    @State private var expanded = false

    private var statusColor: Color {
        switch section.permitStatus {
        case .none: .secondary
        case .applied: .blue
        case .pending: .orange
        case .approved: .green
        case .denied: .red
        }
    }

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            Picker("Status", selection: $section.permitStatus) {
                ForEach(PermitStatus.allCases) { status in
                    Label(status.displayName, systemImage: status.iconName)
                        .tag(status)
                }
            }

            if section.needsPermit {
                TextField("Permit # (optional)", text: $section.permitNumber)
                    .font(.caption)
                    .textFieldStyle(.roundedBorder)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: section.permitStatus.iconName)
                    .foregroundStyle(statusColor)
                    .font(.caption)
                Text(section.permitStatus.displayName)
                    .font(.caption)
                    .foregroundStyle(statusColor)
                if !section.permitNumber.isEmpty {
                    Text("· #\(section.permitNumber)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Line Item

struct LineItemRow: View {
    @Bindable var item: ProposalLineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Description", text: $item.itemDescription)
                .font(.body)

            HStack {
                HStack(spacing: 4) {
                    Text("Qty")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("1", value: $item.quantity, format: .number)
                        .keyboardType(.decimalPad)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 4) {
                    Text("@")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("$0", value: $item.unitPrice, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                }

                TextField("ea", text: $item.unit)
                    .frame(width: 40)
                    .textFieldStyle(.roundedBorder)

                Spacer()

                Text(item.lineTotal.formatted(.currency(code: "USD")))
                    .font(.subheadline.bold())
                    .monospacedDigit()
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}
