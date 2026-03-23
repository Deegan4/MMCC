import SwiftUI
import SwiftData

struct ProposalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ProTierService.self) private var proTierService: ProTierService?
    @Query(sort: \Proposal.updatedAt, order: .reverse) private var proposals: [Proposal]
    @Query private var templates: [JobTemplate]
    @State private var showingNewProposal = false
    @State private var showingTemplateSheet = false
    @State private var showingPaywall = false
    @State private var searchText = ""
    @State private var filterStatus: ProposalStatus?

    private var filteredProposals: [Proposal] {
        proposals.filter { prop in
            let matchesSearch = searchText.isEmpty
                || prop.title.localizedCaseInsensitiveContains(searchText)
                || (prop.customer?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            let matchesFilter = filterStatus == nil || prop.status == filterStatus
            return matchesSearch && matchesFilter
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if proposals.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            if let limitText = proTierService?.proposalLimitText() {
                                UpgradePromptBanner(text: limitText)
                            }
                            statusFilterBar
                            ForEach(filteredProposals) { proposal in
                                NavigationLink(value: proposal) {
                                    ProposalListCard(proposal: proposal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .searchable(text: $searchText, prompt: "Search proposals...")
            .navigationTitle("Proposals")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if proTierService?.canCreateProposal() ?? true {
                            showingTemplateSheet = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.mmccAmber)
                    }
                }
            }
            .navigationDestination(for: Proposal.self) { proposal in
                ProposalDetailView(proposal: proposal)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingTemplateSheet) {
                TemplatePickerSheet(templates: templates) { template in
                    createProposal(from: template)
                } onBlank: {
                    createBlankProposal()
                }
            }
        }
    }

    // MARK: - Filter Bar (PasangLagi-style segmented tabs)

    private var statusFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: filterStatus == nil) {
                    filterStatus = nil
                }
                ForEach(ProposalStatus.allCases) { status in
                    FilterChip(
                        title: status.displayName,
                        isSelected: filterStatus == status,
                        tint: status.color
                    ) {
                        filterStatus = filterStatus == status ? nil : status
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 56))
                .foregroundStyle(.quaternary)

            Text("No Proposals Yet")
                .font(.title3.weight(.semibold))

            Text("Create your first proposal from a\nmarine template or start from scratch")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingTemplateSheet = true
            } label: {
                Label("New Proposal", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .tint(Color.mmccAmber)
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func createProposal(from template: JobTemplate) {
        let proposal = Proposal()
        proposal.title = template.name
        proposal.notes = template.defaultNotes
        proposal.terms = template.defaultTerms
        proposal.markup = template.defaultMarkup
        proposal.taxRate = template.defaultTaxRate
        proposal.sourceTemplateName = template.name
        proposal.number = (proposals.map(\.number).max() ?? 0) + 1

        for templateSection in template.sortedSections {
            let section = ProposalSection(name: templateSection.name, sortOrder: templateSection.sortOrder)
            for item in templateSection.sortedItems {
                let lineItem = ProposalLineItem(
                    description: item.itemDescription,
                    quantity: item.defaultQty,
                    unitPrice: item.defaultPrice,
                    unit: item.unit
                )
                lineItem.sortOrder = item.sortOrder
                if section.lineItems == nil { section.lineItems = [] }
                section.lineItems?.append(lineItem)
            }
            if proposal.sections == nil { proposal.sections = [] }
            proposal.sections?.append(section)
        }

        modelContext.insert(proposal)
        template.usageCount += 1
        showingTemplateSheet = false
    }

    private func createBlankProposal() {
        let proposal = Proposal()
        proposal.number = (proposals.map(\.number).max() ?? 0) + 1
        let section = ProposalSection(name: "Items", sortOrder: 0)
        if proposal.sections == nil { proposal.sections = [] }
        proposal.sections?.append(section)
        modelContext.insert(proposal)
        showingTemplateSheet = false
    }
}

// MARK: - Proposal List Card (PasangLagi-style project card with metrics)

struct ProposalListCard: View {
    let proposal: Proposal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top: number + status
            HStack {
                Text("P-\(String(format: "%03d", proposal.number))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tint)
                Spacer()
                StatusBadge(text: proposal.status.displayName, color: proposal.status.color)
            }

            // Title + customer
            VStack(alignment: .leading, spacing: 2) {
                Text(proposal.title.isEmpty ? "Untitled Proposal" : proposal.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                    Text(proposal.customer?.name ?? "No Customer")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // Metrics row (PasangLagi-style)
            HStack(spacing: 8) {
                MetricBadge(
                    value: "\(proposal.sortedSections.count)",
                    label: "Sections",
                    tint: .statusSent
                )
                MetricBadge(
                    value: "\(proposal.sortedSections.flatMap { $0.sortedLineItems }.count)",
                    label: "Items",
                    tint: .mmccAmber
                )
                MetricBadge(
                    value: proposal.grandTotal.formatted(.currency(code: "USD")),
                    label: "Total",
                    tint: .statusAccepted
                )
            }

            // Date row
            HStack {
                Text(proposal.updatedAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if let template = proposal.sourceTemplateName {
                    Text("·")
                        .foregroundStyle(.quaternary)
                    Text(template)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                Spacer()
            }
        }
        .padding(14)
        .cardBackground(cornerRadius: 14)
    }
}
