import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(SyncCoordinator.self) private var syncCoordinator

    @Query(sort: \Proposal.updatedAt, order: .reverse)
    private var allProposals: [Proposal]

    @Query(sort: \Invoice.createdAt, order: .reverse)
    private var allInvoices: [Invoice]

    private var activeProposals: [Proposal] {
        allProposals.filter { $0.status.isActive }
    }

    private var unpaidInvoices: [Invoice] {
        allInvoices.filter { $0.status == .sent || $0.status == .partiallyPaid || $0.status == .overdue }
    }

    @Query private var profiles: [BusinessProfile]
    @State private var showingSearch = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    brandHeader
                    featureGrid
                    statsRow
                    chartsSection
                    activeProposalsSection
                    unpaidInvoicesSection
                    recentActivity
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            .sheet(isPresented: $showingSearch) {
                GlobalSearchView()
            }
            .toolbarTitleDisplayMode(.inline)
            .navigationDestination(for: Proposal.self) { proposal in
                ProposalDetailView(proposal: proposal)
            }
            .navigationDestination(for: Invoice.self) { invoice in
                InvoiceDetailView(invoice: invoice)
            }
            .onAppear {
                WidgetSyncHelper.shared.update(proposals: allProposals, invoices: allInvoices)
            }
            .onChange(of: allProposals.count) {
                WidgetSyncHelper.shared.syncNow(proposals: allProposals, invoices: allInvoices)
            }
            .onChange(of: allInvoices.count) {
                WidgetSyncHelper.shared.syncNow(proposals: allProposals, invoices: allInvoices)
            }
        }
    }

    // MARK: - Brand Header

    private var brandHeader: some View {
        VStack(spacing: 4) {
            if let name = profiles.first?.businessName, !name.isEmpty {
                Text(name)
                    .font(.title2.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            HStack(spacing: 8) {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if syncCoordinator.isSyncing {
                    ProgressView()
                        .controlSize(.mini)
                } else if syncCoordinator.pendingQueueCount > 0 {
                    Label("\(syncCoordinator.pendingQueueCount)", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.mmccAmber.gradient, in: .capsule)
                } else if syncCoordinator.lastSyncError != nil {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5 ..< 12: return "Good morning"
        case 12 ..< 17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    // MARK: - Feature Grid (PasangLagi-style)

    private var featureGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
            FeatureGridButton(title: "New Bid", icon: "plus.circle.fill", tint: .mmccAmber) {}
            FeatureGridButton(title: "Customers", icon: "person.2.fill", tint: .statusSent) {}
            FeatureGridButton(title: "Materials", icon: "shippingbox.fill", tint: .statusAccepted) {}
            FeatureGridButton(title: "Templates", icon: "doc.on.doc.fill", tint: .statusInvoiced) {}
        }
        .padding(16)
        .cardBackground(cornerRadius: 16)
    }

    // MARK: - Stats Row (PasangLagi metric badges)

    private var statsRow: some View {
        HStack(spacing: 10) {
            MetricBadge(
                value: "\(activeProposals.count)",
                label: "Open",
                tint: .statusSent
            )
            MetricBadge(
                value: "\(allProposals.filter { $0.status == .accepted }.count)",
                label: "Accepted",
                tint: .statusAccepted
            )
            MetricBadge(
                value: "\(unpaidInvoices.count)",
                label: "Unpaid",
                tint: .mmccAmber
            )
            MetricBadge(
                value: winRate,
                label: "Win %",
                tint: .statusAccepted
            )
        }
        .padding(14)
        .cardBackground(cornerRadius: 16)
    }

    private var winRate: String {
        let decided = allProposals.filter { $0.status == .accepted || $0.status == .declined }
        guard !decided.isEmpty else { return "—" }
        let won = decided.filter { $0.status == .accepted }.count
        return "\(Int(Double(won) / Double(decided.count) * 100))"
    }

    private var unpaidTotal: String {
        let total = unpaidInvoices.reduce(Decimal.zero) { $0 + $1.balanceDue }
        return total.formatted(.currency(code: "USD"))
    }

    // MARK: - Charts

    private var chartsSection: some View {
        Group {
            if allInvoices.contains(where: { !($0.payments ?? []).isEmpty }) || allProposals.count >= 3 {
                VStack(spacing: 12) {
                    if allInvoices.contains(where: { !($0.payments ?? []).isEmpty }) {
                        RevenueChartView(invoices: allInvoices)
                    }
                    if allProposals.count >= 3 {
                        ProposalWinRateView(proposals: allProposals)
                    }
                }
            }
        }
    }

    // MARK: - Active Proposals

    private var activeProposalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader("Active Proposals", icon: "doc.text.fill", count: activeProposals.isEmpty ? nil : activeProposals.count)

            if activeProposals.isEmpty {
                EmptyCard(
                    icon: "doc.text",
                    title: "No Active Proposals",
                    subtitle: "Tap the Proposals tab to create your first bid"
                )
            } else {
                ForEach(activeProposals.prefix(5)) { proposal in
                    NavigationLink(value: proposal) {
                        ProposalRow(proposal: proposal)
                    }
                    .buttonStyle(.plain)
                }
                if activeProposals.count > 5 {
                    Text("+ \(activeProposals.count - 5) more")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Unpaid Invoices

    private var unpaidInvoicesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader("Unpaid Invoices", icon: "dollarsign.circle.fill", count: unpaidInvoices.isEmpty ? nil : unpaidInvoices.count)

            if unpaidInvoices.isEmpty {
                EmptyCard(
                    icon: "checkmark.seal.fill",
                    title: "All Caught Up",
                    subtitle: "No outstanding invoices"
                )
            } else {
                ForEach(unpaidInvoices.prefix(5)) { invoice in
                    NavigationLink(value: invoice) {
                        InvoiceRow(invoice: invoice)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Recent Activity

    private var recentActivity: some View {
        Group {
            if let recent = allProposals.first {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader("Recently Updated", icon: "clock.fill")
                    NavigationLink(value: recent) {
                        HStack(spacing: 12) {
                            Image(systemName: recent.status.iconName)
                                .font(.title3)
                                .foregroundStyle(recent.status.color)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(recent.title.isEmpty ? "Untitled" : recent.title)
                                    .font(.subheadline.weight(.medium))
                                Text("Updated \(recent.updatedAt, style: .relative) ago")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.quaternary)
                        }
                        .padding()
                        .cardBackground(cornerRadius: 14)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Stat Card (legacy — kept for chart views)

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white)
                .padding(6)
                .background(tint.gradient, in: .circle)

            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(cornerRadius: 14)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .cardBackground(cornerRadius: 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Proposal Row

struct ProposalRow: View {
    let proposal: Proposal

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: proposal.status.iconName)
                .font(.title3)
                .foregroundStyle(proposal.status.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(proposal.title.isEmpty ? "Untitled Proposal" : proposal.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(proposal.customer?.name ?? "No Customer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let template = proposal.sourceTemplateName {
                        Text("·")
                            .foregroundStyle(.quaternary)
                        Text(template)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(proposal.grandTotal.formatted(.currency(code: "USD")))
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                StatusBadge(text: proposal.status.displayName, color: proposal.status.color)
            }
        }
        .padding(14)
        .cardBackground(cornerRadius: 14)
    }
}

// MARK: - Invoice Row

struct InvoiceRow: View {
    let invoice: Invoice

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(invoice.status.color)
                .frame(width: 10, height: 10)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 3) {
                Text("INV-\(String(format: "%03d", invoice.number))")
                    .font(.subheadline.weight(.semibold))
                Text(invoice.customer?.name ?? "No Customer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(invoice.balanceDue.formatted(.currency(code: "USD")))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(invoice.isOverdue ? Color.statusOverdue : .primary)
                    .monospacedDigit()
                if let due = invoice.dueDate {
                    Text(invoice.isOverdue ? "Overdue" : "Due \(due, style: .date)")
                        .font(.caption2)
                        .foregroundStyle(invoice.isOverdue ? AnyShapeStyle(Color.statusOverdue.opacity(0.8)) : AnyShapeStyle(.tertiary))
                } else {
                    StatusBadge(text: invoice.status.displayName, color: invoice.status.color)
                }
            }
        }
        .padding(14)
        .cardBackground(cornerRadius: 14)
    }
}

// MARK: - Empty Card

struct EmptyCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.quaternary)
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .cardBackground(cornerRadius: 14)
    }
}
