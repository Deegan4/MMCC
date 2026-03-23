import SwiftUI
import SwiftData

struct InvoiceDetailView: View {
    @Bindable var invoice: Invoice
    @Environment(\.modelContext) private var modelContext
    @Environment(SyncCoordinator.self) private var syncCoordinator: SyncCoordinator?
    @Environment(ProTierService.self) private var proTierService: ProTierService?
    @Query private var profiles: [BusinessProfile]
    @State private var showingRecordPayment = false
    @State private var showingShareSheet = false
    @State private var showingSendToCustomer = false
    @State private var pdfData: Data?

    var body: some View {
        Form {
            headerSection
            customerSection
            jobSiteSection

            ForEach(invoice.sortedSections) { section in
                InvoiceSectionView(section: section)
            }

            totalsSection
            paymentsSection
            notesSection
        }
        .navigationTitle("INV-\(String(format: "%03d", invoice.number))")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Send to Customer", systemImage: "paperplane.fill") { sendToCustomer() }
                        .disabled(invoice.customer == nil)
                    Button("Share PDF", systemImage: "square.and.arrow.up") { sharePDF() }
                    Divider()
                    Button("Mark Sent", systemImage: "paperplane") { markSent() }
                        .disabled(invoice.status != .draft)
                    Button("Record Payment", systemImage: "dollarsign.circle") {
                        showingRecordPayment = true
                    }
                    if invoice.status == .sent || invoice.status == .partiallyPaid {
                        Button("Mark Overdue", systemImage: "exclamationmark.triangle") {
                            invoice.status = .overdue
                        }
                    }
                    if invoice.status != .void {
                        Divider()
                        Button("Void Invoice", systemImage: "xmark.circle", role: .destructive) {
                            invoice.status = .void
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingRecordPayment) {
            RecordPaymentSheet(invoice: invoice)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfData {
                ShareSheet(items: [pdfData])
            }
        }
        .sheet(isPresented: $showingSendToCustomer) {
            if let data = pdfData {
                SendToCustomerSheet(
                    documentType: .invoice,
                    documentNumber: "INV-\(String(format: "%03d", invoice.number))",
                    documentTitle: "",
                    customerName: invoice.customer?.name ?? "",
                    customerEmail: invoice.customer?.email ?? "",
                    customerPhone: invoice.customer?.phone ?? "",
                    grandTotal: invoice.grandTotal,
                    pdfData: data,
                    businessName: profiles.first?.businessName ?? "MMCC"
                )
            }
        }
    }

    private var headerSection: some View {
        Section {
            HStack {
                Text("Status")
                Spacer()
                Text(invoice.status.displayName)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15), in: .capsule)
                    .foregroundStyle(statusColor)
            }
            if let dueDate = invoice.dueDate {
                HStack {
                    Text("Due Date")
                    Spacer()
                    Text(dueDate, style: .date)
                        .foregroundStyle(invoice.isOverdue ? .red : .primary)
                }
            }
            Picker("Payment Terms", selection: $invoice.paymentTerms) {
                ForEach(PaymentTerms.allCases) { terms in
                    Text(terms.displayName).tag(terms)
                }
            }
            if invoice.qbInvoiceID != nil {
                Label("Synced to QuickBooks", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }

    private var statusColor: Color {
        switch invoice.status {
        case .draft: .secondary
        case .sent: .blue
        case .partiallyPaid: .orange
        case .paid: .green
        case .overdue: .red
        case .void: .gray
        }
    }

    private var customerSection: some View {
        Section("Customer") {
            if let customer = invoice.customer {
                VStack(alignment: .leading, spacing: 4) {
                    Text(customer.name).font(.body.bold())
                    if !customer.phone.isEmpty {
                        Text(customer.phone).font(.caption).foregroundStyle(.secondary)
                    }
                    if !customer.email.isEmpty {
                        Text(customer.email).font(.caption).foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("No Customer").foregroundStyle(.secondary)
            }
        }
    }

    private var jobSiteSection: some View {
        Group {
            if !invoice.jobAddress.isEmpty || !invoice.waterway.isEmpty {
                Section("Job Site") {
                    if !invoice.jobAddress.isEmpty {
                        LabeledContent("Address", value: invoice.jobAddress)
                    }
                    if !invoice.waterway.isEmpty {
                        LabeledContent("Waterway", value: invoice.waterway)
                    }
                }
            }
        }
    }

    private var totalsSection: some View {
        Section("Totals") {
            HStack {
                Text("Subtotal")
                Spacer()
                Text(invoice.subtotal.formatted(.currency(code: "USD")))
            }
            if invoice.taxAmount > 0 {
                HStack {
                    Text("Tax (\(invoice.taxRate.formatted())%)")
                    Spacer()
                    Text(invoice.taxAmount.formatted(.currency(code: "USD")))
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                Text("Grand Total")
                    .font(.headline)
                Spacer()
                Text(invoice.grandTotal.formatted(.currency(code: "USD")))
                    .font(.headline)
            }
            if invoice.totalPaid > 0 {
                HStack {
                    Text("Paid")
                    Spacer()
                    Text(invoice.totalPaid.formatted(.currency(code: "USD")))
                        .foregroundStyle(.green)
                }
            }
            HStack {
                Text("Balance Due")
                    .font(.headline)
                Spacer()
                Text(invoice.balanceDue.formatted(.currency(code: "USD")))
                    .font(.headline)
                    .foregroundStyle(invoice.isOverdue ? .red : .primary)
            }
        }
    }

    private var paymentsSection: some View {
        Section("Payments") {
            if (invoice.payments ?? []).isEmpty {
                Text("No payments recorded")
                    .foregroundStyle(.secondary)
            } else {
                ForEach((invoice.payments ?? []).sorted(by: { $0.date < $1.date })) { payment in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(payment.amount.formatted(.currency(code: "USD")))
                                .font(.body.bold())
                            Text(payment.method.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !payment.note.isEmpty {
                                Text(payment.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(payment.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: deletePayments)
            }
            Button {
                showingRecordPayment = true
            } label: {
                Label("Record Payment", systemImage: "plus.circle")
            }
        }
    }

    private var notesSection: some View {
        Section("Notes & Terms") {
            if !invoice.notes.isEmpty {
                Text(invoice.notes)
                    .font(.body)
            }
            if !invoice.terms.isEmpty {
                Text(invoice.terms)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if invoice.notes.isEmpty && invoice.terms.isEmpty {
                Text("No notes or terms")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func sendToCustomer() {
        let profile = profiles.first ?? BusinessProfile()
        let isPro = proTierService?.isPro ?? false
        pdfData = PDFGenerator.generateInvoicePDF(invoice: invoice, profile: profile, isPro: isPro)
        showingSendToCustomer = true
    }

    private func sharePDF() {
        let profile = profiles.first ?? BusinessProfile()
        let isPro = proTierService?.isPro ?? false
        pdfData = PDFGenerator.generateInvoicePDF(invoice: invoice, profile: profile, isPro: isPro)
        showingShareSheet = true
    }

    private func markSent() {
        invoice.status = .sent
        invoice.sentAt = .now
        // Set due date based on payment terms
        switch invoice.paymentTerms {
        case .dueOnReceipt: invoice.dueDate = .now
        case .net15: invoice.dueDate = Calendar.current.date(byAdding: .day, value: 15, to: .now)
        case .net30: invoice.dueDate = Calendar.current.date(byAdding: .day, value: 30, to: .now)
        case .net45: invoice.dueDate = Calendar.current.date(byAdding: .day, value: 45, to: .now)
        case .net60: invoice.dueDate = Calendar.current.date(byAdding: .day, value: 60, to: .now)
        case .thirdThirdThird, .fiftyFifty: invoice.dueDate = Calendar.current.date(byAdding: .day, value: 30, to: .now)
        }
        // Push to QuickBooks if connected (ADR-004: push-on-action)
        if let profile = profiles.first, profile.qbConnected {
            Task { await syncCoordinator?.syncInvoice(invoice) }
        }
    }

    private func deletePayments(at offsets: IndexSet) {
        let sorted = (invoice.payments ?? []).sorted(by: { $0.date < $1.date })
        for index in offsets {
            modelContext.delete(sorted[index])
        }
        updateInvoiceStatus()
    }

    private func updateInvoiceStatus() {
        if invoice.balanceDue <= 0 {
            invoice.status = .paid
        } else if invoice.totalPaid > 0 {
            invoice.status = .partiallyPaid
        }
    }
}

// MARK: - Invoice Section View

struct InvoiceSectionView: View {
    let section: InvoiceSection

    var body: some View {
        Section(section.name) {
            ForEach(section.sortedLineItems) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.itemDescription)
                            .font(.body)
                        Text("\(item.quantity.formatted()) \(item.unit) @ \(item.unitPrice.formatted(.currency(code: "USD")))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(item.lineTotal.formatted(.currency(code: "USD")))
                        .font(.subheadline.bold())
                        .monospacedDigit()
                }
            }

            HStack {
                Spacer()
                Text("Section Total: \(section.subtotal.formatted(.currency(code: "USD")))")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Record Payment Sheet

struct RecordPaymentSheet: View {
    let invoice: Invoice
    @Environment(\.modelContext) private var modelContext
    @Environment(SyncCoordinator.self) private var syncCoordinator: SyncCoordinator?
    @Environment(\.dismiss) private var dismiss

    @State private var amount: Decimal = 0
    @State private var method: PaymentMethod = .check
    @State private var date: Date = .now
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Payment Details") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("$0", value: $amount, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    Picker("Method", selection: $method) {
                        ForEach(PaymentMethod.allCases) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Note (optional)", text: $note)
                }

                Section {
                    HStack {
                        Text("Balance Due")
                        Spacer()
                        Text(invoice.balanceDue.formatted(.currency(code: "USD")))
                            .foregroundStyle(.secondary)
                    }
                    if amount > 0 {
                        HStack {
                            Text("After Payment")
                            Spacer()
                            Text((invoice.balanceDue - amount).formatted(.currency(code: "USD")))
                                .foregroundStyle(invoice.balanceDue - amount <= 0 ? .green : .primary)
                        }
                    }
                }
            }
            .navigationTitle("Record Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { savePayment() }
                        .disabled(amount <= 0)
                }
            }
            .onAppear {
                amount = invoice.balanceDue
            }
        }
    }

    private func savePayment() {
        let payment = Payment(amount: amount, method: method)
        payment.date = date
        payment.note = note
        if invoice.payments == nil { invoice.payments = [] }
        invoice.payments?.append(payment)

        // Update status
        if invoice.balanceDue - amount <= 0 {
            invoice.status = .paid
        } else {
            invoice.status = .partiallyPaid
        }

        // Push payment to QuickBooks if connected
        if invoice.customer?.qbCustomerID != nil || invoice.qbInvoiceID != nil {
            Task { await syncCoordinator?.syncPayment(payment, invoice: invoice) }
        }

        dismiss()
    }
}
