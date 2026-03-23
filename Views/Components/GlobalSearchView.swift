import SwiftUI
import SwiftData

/// Federated search across Proposals, Invoices, Customers, and Saved Items.
/// Presented as a full-screen sheet from the tab bar or dashboard.
struct GlobalSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var proposalResults: [Proposal] = []
    @State private var invoiceResults: [Invoice] = []
    @State private var customerResults: [Customer] = []
    @State private var savedItemResults: [SavedItem] = []

    private var hasResults: Bool {
        !proposalResults.isEmpty || !invoiceResults.isEmpty || !customerResults.isEmpty || !savedItemResults.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    recentHint
                } else if !hasResults {
                    noResults
                } else {
                    if !proposalResults.isEmpty {
                        proposalSection
                    }
                    if !invoiceResults.isEmpty {
                        invoiceSection
                    }
                    if !customerResults.isEmpty {
                        customerSection
                    }
                    if !savedItemResults.isEmpty {
                        savedItemSection
                    }
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Proposals, invoices, customers, items…")
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationDestination(for: Proposal.self) { proposal in
                ProposalDetailView(proposal: proposal)
            }
            .navigationDestination(for: Invoice.self) { invoice in
                InvoiceDetailView(invoice: invoice)
            }
            .navigationDestination(for: Customer.self) { customer in
                CustomerSearchDetailView(customer: customer)
            }
            .onChange(of: query) {
                performSearch()
            }
        }
    }

    // MARK: - Sections

    private var recentHint: some View {
        ContentUnavailableView {
            Label("Search Everything", systemImage: "magnifyingglass")
        } description: {
            Text("Find proposals, invoices, customers, and library items by name, number, address, or waterway.")
        }
    }

    private var noResults: some View {
        ContentUnavailableView.search(text: query)
    }

    private var proposalSection: some View {
        Section {
            ForEach(proposalResults) { proposal in
                NavigationLink(value: proposal) {
                    SearchResultRow(
                        icon: proposal.status.iconName,
                        iconColor: proposal.status.color,
                        title: proposal.title.isEmpty ? "Untitled Proposal" : proposal.title,
                        subtitle: "P-\(String(format: "%03d", proposal.number)) · \(proposal.customer?.name ?? "No Customer")",
                        detail: proposal.grandTotal.formatted(.currency(code: "USD"))
                    )
                }
            }
        } header: {
            Label("Proposals (\(proposalResults.count))", systemImage: "doc.text.fill")
        }
    }

    private var invoiceSection: some View {
        Section {
            ForEach(invoiceResults) { invoice in
                NavigationLink(value: invoice) {
                    SearchResultRow(
                        icon: "dollarsign.circle.fill",
                        iconColor: invoice.status.color,
                        title: "INV-\(String(format: "%03d", invoice.number))",
                        subtitle: invoice.customer?.name ?? "No Customer",
                        detail: invoice.balanceDue.formatted(.currency(code: "USD"))
                    )
                }
            }
        } header: {
            Label("Invoices (\(invoiceResults.count))", systemImage: "dollarsign.circle.fill")
        }
    }

    private var customerSection: some View {
        Section {
            ForEach(customerResults) { customer in
                NavigationLink(value: customer) {
                    SearchResultRow(
                        icon: "person.fill",
                        iconColor: .mmccAmber,
                        title: customer.name,
                        subtitle: [customer.phone, customer.email].filter { !$0.isEmpty }.joined(separator: " · "),
                        detail: customer.waterway.isEmpty ? nil : customer.waterway
                    )
                }
            }
        } header: {
            Label("Customers (\(customerResults.count))", systemImage: "person.2.fill")
        }
    }

    private var savedItemSection: some View {
        Section {
            ForEach(savedItemResults) { item in
                SearchResultRow(
                    icon: "tray.fill",
                    iconColor: .statusAccepted,
                    title: item.itemDescription,
                    subtitle: item.category.displayName,
                    detail: item.defaultPrice.formatted(.currency(code: "USD"))
                )
            }
        } header: {
            Label("Library Items (\(savedItemResults.count))", systemImage: "tray.full.fill")
        }
    }

    // MARK: - Search Logic

    private func performSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            proposalResults = []
            invoiceResults = []
            customerResults = []
            savedItemResults = []
            return
        }

        let q = trimmed.localizedLowercase

        // Proposals: search title, customer name, job address, waterway, number
        do {
            let descriptor = FetchDescriptor<Proposal>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
            let all = try modelContext.fetch(descriptor)
            proposalResults = all.filter { proposal in
                proposal.title.localizedCaseInsensitiveContains(q)
                || proposal.customer?.name.localizedCaseInsensitiveContains(q) == true
                || proposal.jobAddress.localizedCaseInsensitiveContains(q)
                || proposal.waterway.localizedCaseInsensitiveContains(q)
                || "p-\(String(format: "%03d", proposal.number))".contains(q)
                || proposal.notes.localizedCaseInsensitiveContains(q)
            }
        } catch { proposalResults = [] }

        // Invoices: search number, customer name, job address
        do {
            let descriptor = FetchDescriptor<Invoice>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            let all = try modelContext.fetch(descriptor)
            invoiceResults = all.filter { invoice in
                "inv-\(String(format: "%03d", invoice.number))".contains(q)
                || invoice.customer?.name.localizedCaseInsensitiveContains(q) == true
                || invoice.jobAddress.localizedCaseInsensitiveContains(q)
                || invoice.waterway.localizedCaseInsensitiveContains(q)
            }
        } catch { invoiceResults = [] }

        // Customers: search name, phone, email, address, waterway
        do {
            let descriptor = FetchDescriptor<Customer>(sortBy: [SortDescriptor(\.name)])
            let all = try modelContext.fetch(descriptor)
            customerResults = all.filter { customer in
                customer.name.localizedCaseInsensitiveContains(q)
                || customer.phone.localizedCaseInsensitiveContains(q)
                || customer.email.localizedCaseInsensitiveContains(q)
                || customer.address.localizedCaseInsensitiveContains(q)
                || customer.waterway.localizedCaseInsensitiveContains(q)
            }
        } catch { customerResults = [] }

        // Saved Items: search description, category
        do {
            let descriptor = FetchDescriptor<SavedItem>(sortBy: [SortDescriptor(\.usageCount, order: .reverse)])
            let all = try modelContext.fetch(descriptor)
            savedItemResults = all.filter { item in
                item.itemDescription.localizedCaseInsensitiveContains(q)
                || item.category.displayName.localizedCaseInsensitiveContains(q)
            }
        } catch { savedItemResults = [] }
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let detail: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let detail {
                Text(detail)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Customer Detail (for search navigation)

/// Lightweight customer detail shown when tapping a customer from search results.
struct CustomerSearchDetailView: View {
    let customer: Customer

    var body: some View {
        Form {
            Section("Contact") {
                if !customer.name.isEmpty {
                    LabeledContent("Name", value: customer.name)
                }
                if !customer.phone.isEmpty {
                    LabeledContent("Phone", value: customer.phone)
                }
                if !customer.email.isEmpty {
                    LabeledContent("Email", value: customer.email)
                }
                if !customer.address.isEmpty {
                    LabeledContent("Address", value: customer.address)
                }
            }

            if !customer.waterway.isEmpty || customer.waterwayType != nil || customer.existingSeawallType != nil {
                Section("Waterfront") {
                    if !customer.waterway.isEmpty {
                        LabeledContent("Waterway", value: customer.waterway)
                    }
                    if let type = customer.waterwayType {
                        LabeledContent("Type", value: type.displayName)
                    }
                    if let seawall = customer.existingSeawallType {
                        LabeledContent("Seawall", value: seawall.displayName)
                    }
                    if let depth = customer.waterDepthFeet {
                        LabeledContent("Water Depth", value: "\(depth.formatted()) ft")
                    }
                    if customer.isTidal {
                        Label("Tidal", systemImage: "water.waves")
                    }
                }
            }

            if let proposals = customer.proposals, !proposals.isEmpty {
                Section("Proposals (\(proposals.count))") {
                    ForEach(proposals.sorted(by: { $0.updatedAt > $1.updatedAt }).prefix(5), id: \.id) { proposal in
                        NavigationLink(value: proposal) {
                            HStack {
                                Text(proposal.title.isEmpty ? "Untitled" : proposal.title)
                                    .font(.subheadline)
                                Spacer()
                                StatusBadge(text: proposal.status.displayName, color: proposal.status.color)
                            }
                        }
                    }
                }
            }

            if let invoices = customer.invoices, !invoices.isEmpty {
                Section("Invoices (\(invoices.count))") {
                    ForEach(invoices.sorted(by: { $0.createdAt > $1.createdAt }).prefix(5), id: \.id) { invoice in
                        NavigationLink(value: invoice) {
                            HStack {
                                Text("INV-\(String(format: "%03d", invoice.number))")
                                    .font(.subheadline)
                                Spacer()
                                Text(invoice.balanceDue.formatted(.currency(code: "USD")))
                                    .font(.caption.bold())
                                    .foregroundStyle(invoice.isOverdue ? .red : .secondary)
                            }
                        }
                    }
                }
            }

            if !customer.notes.isEmpty {
                Section("Notes") {
                    Text(customer.notes)
                        .font(.body)
                }
            }
        }
        .navigationTitle(customer.name)
    }
}
