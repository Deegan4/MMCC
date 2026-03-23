import SwiftUI
import SwiftData

struct InvoiceListView: View {
    @Query(sort: \Invoice.createdAt, order: .reverse) private var invoices: [Invoice]

    var body: some View {
        NavigationStack {
            Group {
                if invoices.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(invoices) { invoice in
                                NavigationLink(value: invoice) {
                                    InvoiceListCard(invoice: invoice)
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
            .navigationTitle("Invoices")
            .toolbarTitleDisplayMode(.inline)
            .navigationDestination(for: Invoice.self) { invoice in
                InvoiceDetailView(invoice: invoice)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 56))
                .foregroundStyle(.quaternary)

            Text("No Invoices Yet")
                .font(.title3.weight(.semibold))

            Text("Convert an accepted proposal\nto create your first invoice")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Invoice List Card

struct InvoiceListCard: View {
    let invoice: Invoice

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top: number + status
            HStack {
                Text("INV-\(String(format: "%03d", invoice.number))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tint)
                Spacer()
                StatusBadge(text: invoice.status.displayName, color: invoice.status.color)
            }

            // Customer
            Text(invoice.customer?.name ?? "No Customer")
                .font(.body.weight(.semibold))
                .lineLimit(1)

            // Bottom: due date + totals
            HStack {
                if let due = invoice.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: invoice.isOverdue ? "exclamationmark.triangle.fill" : "calendar")
                            .font(.caption2)
                        Text(invoice.isOverdue ? "Overdue" : "Due \(due, style: .date)")
                    }
                    .font(.caption)
                    .foregroundStyle(invoice.isOverdue ? Color.statusOverdue : .secondary)
                } else {
                    Text(invoice.createdAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(invoice.balanceDue.formatted(.currency(code: "USD")))
                        .font(.headline)
                        .foregroundStyle(invoice.isOverdue ? Color.statusOverdue : .primary)
                        .monospacedDigit()
                    if invoice.totalPaid > 0 {
                        Text("of \(invoice.grandTotal.formatted(.currency(code: "USD")))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                    }
                }
            }

            // Payment progress bar
            if invoice.totalPaid > 0, invoice.grandTotal > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.quaternary)
                            .frame(height: 4)
                        Capsule()
                            .fill(Color.statusAccepted.gradient)
                            .frame(width: max(0, geo.size.width * paymentProgress), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(14)
        .cardBackground(cornerRadius: 14)
    }

    private var paymentProgress: CGFloat {
        guard invoice.grandTotal > 0 else { return 0 }
        return CGFloat(truncating: (invoice.totalPaid / invoice.grandTotal) as NSDecimalNumber)
    }
}
