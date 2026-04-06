import SwiftUI
import SwiftData

struct ProposalDetailView: View {
    @Bindable var proposal: Proposal
    @Environment(\.modelContext) private var modelContext
    @Environment(SyncCoordinator.self) private var syncCoordinator: SyncCoordinator?
    @Environment(ProTierService.self) private var proTierService: ProTierService?
    @Query private var customers: [Customer]
    @Query private var profiles: [BusinessProfile]
    @Query(sort: \Invoice.createdAt, order: .reverse) private var allInvoices: [Invoice]
    @State private var showingCustomerPicker = false
    @State private var showingConvertConfirm = false
    @State private var createdInvoice: Invoice?
    @State private var showingShareSheet = false
    @State private var showingPaywall = false
    @State private var pdfData: Data?
    @State private var showingDriveUploadSuccess = false
    @State private var driveUploading = false
    @State private var showingSaveAsTemplate = false
    @State private var showingSendToCustomer = false

    var body: some View {
        Form {
            headerSection
            customerSection
            jobSiteSection

            ForEach(proposal.sortedSections) { section in
                ProposalSectionView(section: section, proposal: proposal)
            }

            addSectionButton
            totalsSection
            notesSection
        }
        .navigationTitle("P-\(String(format: "%03d", proposal.number))")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Send to Customer", systemImage: "paperplane.fill") { sendToCustomer() }
                        .disabled(proposal.customer == nil)
                    Button("Share PDF", systemImage: "square.and.arrow.up") { sharePDF() }
                    Button("Save to Google Drive", systemImage: "icloud.and.arrow.up") { saveToDrive() }
                        .disabled(driveUploading)
                    Divider()
                    Button("Mark Sent", systemImage: "paperplane") { markSent() }
                        .disabled(proposal.status == .sent || proposal.status == .invoiced)
                    Button("Mark Accepted", systemImage: "checkmark.circle") {
                        proposal.status = .accepted
                        proposal.acceptedAt = .now
                    }
                    .disabled(proposal.status == .accepted || proposal.status == .invoiced)
                    if proposal.status == .accepted {
                        Button("Convert to Invoice", systemImage: "doc.text.fill") {
                            if proTierService?.canCreateInvoice() ?? true {
                                showingConvertConfirm = true
                            } else {
                                showingPaywall = true
                            }
                        }
                    }
                    Divider()
                    Button("Duplicate", systemImage: "doc.on.doc") { duplicateProposal() }
                    Button("Save as Template", systemImage: "square.and.arrow.down.on.square") {
                        showingSaveAsTemplate = true
                    }
                    if proposal.status != .declined {
                        Button("Decline", systemImage: "xmark.circle", role: .destructive) {
                            proposal.status = .declined
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingCustomerPicker) {
            CustomerPickerSheet(customers: customers, proposal: proposal)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .alert("Convert to Invoice?", isPresented: $showingConvertConfirm) {
            Button("Convert") { convertToInvoice() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will create an invoice from this proposal and mark it as invoiced. The proposal will no longer be editable.")
        }
        .navigationDestination(item: $createdInvoice) { invoice in
            InvoiceDetailView(invoice: invoice)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfData {
                ShareSheet(items: [pdfData])
            }
        }
        .sheet(isPresented: $showingSaveAsTemplate) {
            SaveAsTemplateSheet(proposal: proposal)
        }
        .sheet(isPresented: $showingSendToCustomer) {
            if let data = pdfData {
                SendToCustomerSheet(
                    documentType: .proposal,
                    documentNumber: "P-\(String(format: "%03d", proposal.number))",
                    documentTitle: proposal.title,
                    customerName: proposal.customer?.name ?? "",
                    customerEmail: proposal.customer?.email ?? "",
                    customerPhone: proposal.customer?.phone ?? "",
                    grandTotal: proposal.grandTotal,
                    pdfData: data,
                    businessName: profiles.first?.businessName ?? "MMCC"
                )
            }
        }
        .onChange(of: proposal.title) { proposal.updatedAt = .now }
    }

    private var headerSection: some View {
        Section {
            TextField("Proposal Title", text: $proposal.title)
                .font(.headline)
            Picker("Status", selection: $proposal.status) {
                ForEach(ProposalStatus.allCases) { status in
                    Text(status.displayName).tag(status)
                }
            }
            if proposal.qbProposalID != nil {
                Label("Synced to QuickBooks", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }

    private var customerSection: some View {
        Section("Customer") {
            if let customer = proposal.customer {
                VStack(alignment: .leading) {
                    Text(customer.name).font(.body.bold())
                    if !customer.phone.isEmpty {
                        Text(customer.phone).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Button("Change Customer") { showingCustomerPicker = true }
            } else {
                Button("Add Customer") { showingCustomerPicker = true }
            }
        }
    }

    private var jobSiteSection: some View {
        Section("Job Details") {
            TextField("Job Address", text: $proposal.jobAddress)
                .textContentType(.fullStreetAddress)
            Picker("System Type", selection: $proposal.systemType) {
                Text("Not Set").tag(SystemType?.none)
                ForEach(SystemType.allCases) { type in
                    Text(type.displayName).tag(Optional(type))
                }
            }
            Picker("Service Type", selection: $proposal.serviceType) {
                Text("Not Set").tag(ServiceType?.none)
                ForEach(ServiceType.allCases) { type in
                    Text(type.displayName).tag(Optional(type))
                }
            }
            Picker("Property Type", selection: $proposal.propertyType) {
                Text("Not Set").tag(PropertyType?.none)
                ForEach(PropertyType.allCases) { type in
                    Text(type.displayName).tag(Optional(type))
                }
            }
        }
    }

    private var addSectionButton: some View {
        Section {
            Menu {
                ForEach(HVACSection.allCases) { section in
                    Button(section.displayName) {
                        addSection(named: section.displayName, sortOrder: section.defaultSortOrder)
                    }
                }
            } label: {
                Label("Add Section", systemImage: "plus.circle")
            }
        }
    }

    private var totalsSection: some View {
        Section("Totals") {
            HStack {
                Text("Subtotal")
                Spacer()
                Text(proposal.subtotal.formatted(.currency(code: "USD")))
            }
            HStack {
                Text("Markup %")
                Spacer()
                TextField("0", value: $proposal.markup, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
            }
            if proposal.markupAmount > 0 {
                HStack {
                    Text("Markup Amount")
                    Spacer()
                    Text(proposal.markupAmount.formatted(.currency(code: "USD")))
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                Text("Tax %")
                Spacer()
                TextField("0", value: $proposal.taxRate, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
            }
            if proposal.taxAmount > 0 {
                HStack {
                    Text("Tax Amount")
                    Spacer()
                    Text(proposal.taxAmount.formatted(.currency(code: "USD")))
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                Text("Grand Total")
                    .font(.headline)
                Spacer()
                Text(proposal.grandTotal.formatted(.currency(code: "USD")))
                    .font(.headline)
            }
        }
    }

    private var notesSection: some View {
        Section("Notes & Terms") {
            TextEditor(text: $proposal.notes)
                .frame(minHeight: 60)
            TextEditor(text: $proposal.terms)
                .frame(minHeight: 60)
        }
    }

    // MARK: - Actions

    private func addSection(named name: String, sortOrder: Int) {
        let section = ProposalSection(name: name, sortOrder: (proposal.sections ?? []).count)
        if proposal.sections == nil { proposal.sections = [] }
        proposal.sections?.append(section)
    }

    private func sendToCustomer() {
        let profile = profiles.first ?? BusinessProfile()
        let isPro = proTierService?.isPro ?? false
        pdfData = PDFGenerator.generateProposalPDF(proposal: proposal, profile: profile, isPro: isPro)
        showingSendToCustomer = true
    }

    private func sharePDF() {
        let profile = profiles.first ?? BusinessProfile()
        let isPro = proTierService?.isPro ?? false
        pdfData = PDFGenerator.generateProposalPDF(proposal: proposal, profile: profile, isPro: isPro)
        showingShareSheet = true
    }

    private func saveToDrive() {
        driveUploading = true
        let profile = profiles.first ?? BusinessProfile()
        let isPro = proTierService?.isPro ?? false
        _ = PDFGenerator.generateProposalPDF(proposal: proposal, profile: profile, isPro: isPro)
        let _ = "P-\(String(format: "%03d", proposal.number)) \(proposal.title.isEmpty ? "Proposal" : proposal.title).pdf"

        Task {
            driveUploading = false
            showingDriveUploadSuccess = true
        }
    }

    private func markSent() {
        proposal.status = .sent
        proposal.sentAt = .now
        if let profile = profiles.first, profile.qbConnected {
            Task { await syncCoordinator?.syncProposal(proposal) }
        }
    }

    private func duplicateProposal() {
        let copy = Proposal()
        copy.title = "\(proposal.title) (Copy)"
        copy.notes = proposal.notes
        copy.terms = proposal.terms
        copy.markup = proposal.markup
        copy.taxRate = proposal.taxRate
        copy.jobAddress = proposal.jobAddress
        copy.systemType = proposal.systemType
        copy.serviceType = proposal.serviceType
        copy.propertyType = proposal.propertyType
        copy.customer = proposal.customer
        copy.sourceTemplateName = proposal.sourceTemplateName

        let maxNumber = (try? modelContext.fetch(FetchDescriptor<Proposal>()))?.map(\.number).max() ?? 0
        copy.number = maxNumber + 1

        for section in proposal.sortedSections {
            let newSection = ProposalSection(name: section.name, sortOrder: section.sortOrder)
            for item in section.sortedLineItems {
                let newItem = ProposalLineItem(
                    description: item.itemDescription,
                    quantity: item.quantity,
                    unitPrice: item.unitPrice,
                    unit: item.unit
                )
                newItem.sortOrder = item.sortOrder
                newItem.savedItemID = item.savedItemID
                if newSection.lineItems == nil { newSection.lineItems = [] }
                newSection.lineItems?.append(newItem)
            }
            if copy.sections == nil { copy.sections = [] }
            copy.sections?.append(newSection)
        }

        modelContext.insert(copy)
        proposal.updatedAt = .now
    }

    private func convertToInvoice() {
        let invoice = Invoice()

        let maxNumber = allInvoices.map(\.number).max() ?? 0
        invoice.number = maxNumber + 1

        invoice.customer = proposal.customer
        invoice.jobAddress = proposal.jobAddress
        invoice.taxRate = proposal.taxRate
        invoice.notes = proposal.notes
        invoice.terms = proposal.terms
        invoice.sourceProposalID = proposal.id

        for section in proposal.sortedSections {
            let invoiceSection = InvoiceSection(name: section.name, sortOrder: section.sortOrder)
            for item in section.sortedLineItems {
                let invoiceItem = InvoiceLineItem()
                invoiceItem.itemDescription = item.itemDescription
                let markupMultiplier = proposal.markup > 0 ? (1 + proposal.markup / 100) : 1
                invoiceItem.unitPrice = item.unitPrice * markupMultiplier
                invoiceItem.quantity = item.quantity
                invoiceItem.unit = item.unit
                invoiceItem.sortOrder = item.sortOrder
                if invoiceSection.lineItems == nil { invoiceSection.lineItems = [] }
                invoiceSection.lineItems?.append(invoiceItem)
            }
            if invoice.sections == nil { invoice.sections = [] }
            invoice.sections?.append(invoiceSection)
        }

        modelContext.insert(invoice)
        proposal.status = .invoiced
        proposal.updatedAt = .now

        createdInvoice = invoice
    }
}
