import Foundation
import SwiftData

// MARK: - QBSyncService

@MainActor
final class QBSyncService {
    private let apiClient: QBAPIClient
    private let modelContext: ModelContext

    init(apiClient: QBAPIClient, modelContext: ModelContext) {
        self.apiClient = apiClient
        self.modelContext = modelContext
    }

    // MARK: - Customer Push

    func pushCustomer(_ customer: Customer, realmID: String) async throws {
        var body: [String: Any] = [
            "DisplayName": customer.name,
        ]
        if !customer.phone.isEmpty {
            body["PrimaryPhone"] = ["FreeFormNumber": customer.phone]
        }
        if !customer.email.isEmpty {
            body["PrimaryEmailAddr"] = ["Address": customer.email]
        }
        if !customer.address.isEmpty {
            body["BillAddr"] = ["Line1": customer.address]
        }
        if !customer.notes.isEmpty {
            body["Notes"] = customer.notes
        }

        // If updating existing, include Id
        if let qbID = customer.qbCustomerID {
            body["Id"] = qbID
            body["sparse"] = true
        }

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        let responseData = try await apiClient.post(path: "customer", realmID: realmID, body: jsonData)
        let created = try JSONDecoder().decode(QBEntityResponse<QBCreatedEntity>.self, from: responseData)
        customer.qbCustomerID = created.entity.Id
    }

    // MARK: - Customer Pull

    func pullCustomers(realmID: String) async throws -> [QBCustomerDTO] {
        let data = try await apiClient.query(realmID: realmID, sql: "SELECT * FROM Customer WHERE Active = true MAXRESULTS 1000")
        let response = try JSONDecoder().decode(QBQueryResponse<QBCustomerDTO>.self, from: data)
        return response.QueryResponse.items
    }

    // MARK: - Items/Products Pull

    func pullItems(realmID: String) async throws -> [QBItemDTO] {
        let data = try await apiClient.query(realmID: realmID, sql: "SELECT * FROM Item WHERE Active = true MAXRESULTS 1000")
        let response = try JSONDecoder().decode(QBQueryResponse<QBItemDTO>.self, from: data)
        return response.QueryResponse.items
    }

    // MARK: - Tax Rates Pull

    func pullTaxRates(realmID: String) async throws -> [QBTaxRateDTO] {
        let data = try await apiClient.query(realmID: realmID, sql: "SELECT * FROM TaxRate")
        let response = try JSONDecoder().decode(QBQueryResponse<QBTaxRateDTO>.self, from: data)
        return response.QueryResponse.items
    }

    // MARK: - Proposal Push (QB API entity is still "Estimate")

    func pushProposal(_ proposal: Proposal, realmID: String) async throws {
        // Ensure customer is synced first
        if let customer = proposal.customer, customer.qbCustomerID == nil {
            try await pushCustomer(customer, realmID: realmID)
        }

        var body: [String: Any] = [:]

        // Customer reference
        if let qbCustomerID = proposal.customer?.qbCustomerID {
            body["CustomerRef"] = ["value": qbCustomerID]
        }

        body["DocNumber"] = "P-\(proposal.number)"
        body["TxnDate"] = Self.formatDate(proposal.createdAt)

        if let validUntil = proposal.validUntil {
            body["ExpirationDate"] = Self.formatDate(validUntil)
        }

        if !proposal.notes.isEmpty {
            body["CustomerMemo"] = ["value": proposal.notes]
        }

        // Build lines with section headers
        body["Line"] = buildSectionLines(
            sections: proposal.sortedSections,
            sectionName: { $0.name },
            lineItems: { $0.sortedLineItems },
            itemDescription: { $0.itemDescription },
            quantity: { $0.quantity },
            unitPrice: { $0.unitPrice },
            qbItemRef: { $0.qbItemRef },
            lineTotal: { $0.lineTotal }
        )

        // If updating existing
        if let qbID = proposal.qbProposalID {
            body["Id"] = qbID
            body["sparse"] = true
        }

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        // QB API endpoint is still "estimate" — that's QuickBooks' entity name
        let responseData = try await apiClient.post(path: "estimate", realmID: realmID, body: jsonData)
        let created = try JSONDecoder().decode(QBEntityResponse<QBCreatedEntity>.self, from: responseData)
        proposal.qbProposalID = created.entity.Id
        proposal.qbDocNumber = created.entity.DocNumber
    }

    // MARK: - Invoice Push

    func pushInvoice(_ invoice: Invoice, realmID: String) async throws {
        // Ensure customer is synced first
        if let customer = invoice.customer, customer.qbCustomerID == nil {
            try await pushCustomer(customer, realmID: realmID)
        }

        var body: [String: Any] = [:]

        if let qbCustomerID = invoice.customer?.qbCustomerID {
            body["CustomerRef"] = ["value": qbCustomerID]
        }

        body["DocNumber"] = "INV-\(invoice.number)"
        body["TxnDate"] = Self.formatDate(invoice.createdAt)

        if let dueDate = invoice.dueDate {
            body["DueDate"] = Self.formatDate(dueDate)
        }

        if !invoice.notes.isEmpty {
            body["CustomerMemo"] = ["value": invoice.notes]
        }

        // Link to source proposal if it was synced to QB
        if let sourceProposalID = invoice.sourceProposalID {
            let descriptor = FetchDescriptor<Proposal>(predicate: #Predicate { $0.id == sourceProposalID })
            if let sourceProposal = try? modelContext.fetch(descriptor).first,
               let qbProposalID = sourceProposal.qbProposalID
            {
                body["LinkedTxn"] = [["TxnId": qbProposalID, "TxnType": "Estimate"]]
            }
        }

        // Build lines with section headers
        body["Line"] = buildSectionLines(
            sections: invoice.sortedSections,
            sectionName: { $0.name },
            lineItems: { $0.sortedLineItems },
            itemDescription: { $0.itemDescription },
            quantity: { $0.quantity },
            unitPrice: { $0.unitPrice },
            qbItemRef: { $0.qbItemRef },
            lineTotal: { $0.lineTotal }
        )

        if let qbID = invoice.qbInvoiceID {
            body["Id"] = qbID
            body["sparse"] = true
        }

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        let responseData = try await apiClient.post(path: "invoice", realmID: realmID, body: jsonData)
        let created = try JSONDecoder().decode(QBEntityResponse<QBCreatedEntity>.self, from: responseData)
        invoice.qbInvoiceID = created.entity.Id
    }

    // MARK: - Payment Push

    func pushPayment(_ payment: Payment, invoice: Invoice, realmID: String) async throws {
        guard let qbInvoiceID = invoice.qbInvoiceID else {
            // Push the invoice first if it hasn't been synced
            try await pushInvoice(invoice, realmID: realmID)
            guard invoice.qbInvoiceID != nil else { return }
            try await pushPayment(payment, invoice: invoice, realmID: realmID)
            return
        }

        var body: [String: Any] = [
            "TotalAmt": NSDecimalNumber(decimal: payment.amount).doubleValue,
            "TxnDate": Self.formatDate(payment.date),
        ]

        if let qbCustomerID = invoice.customer?.qbCustomerID {
            body["CustomerRef"] = ["value": qbCustomerID]
        }

        // Map MMCC payment method to QB payment method name
        body["PaymentMethodRef"] = ["value": mapPaymentMethod(payment.method)]

        // Link payment to invoice
        body["Line"] = [[
            "Amount": NSDecimalNumber(decimal: payment.amount).doubleValue,
            "LinkedTxn": [["TxnId": qbInvoiceID, "TxnType": "Invoice"]],
        ] as [String: Any]]

        if let qbID = payment.qbPaymentID {
            body["Id"] = qbID
            body["sparse"] = true
        }

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        let responseData = try await apiClient.post(path: "payment", realmID: realmID, body: jsonData)
        let created = try JSONDecoder().decode(QBEntityResponse<QBCreatedEntity>.self, from: responseData)
        payment.qbPaymentID = created.entity.Id
    }

    // MARK: - Section → QB Line Mapping

    /// Generic section-to-QB-line builder that works for both Proposal and Invoice sections.
    /// QB has no sections — we emulate them with DescriptionOnly headers and SubTotalLineDetail footers.
    private func buildSectionLines<Section, LineItem>(
        sections: [Section],
        sectionName: (Section) -> String,
        lineItems: (Section) -> [LineItem],
        itemDescription: (LineItem) -> String,
        quantity: (LineItem) -> Decimal,
        unitPrice: (LineItem) -> Decimal,
        qbItemRef: (LineItem) -> String?,
        lineTotal: (LineItem) -> Decimal
    ) -> [[String: Any]] {
        var lines: [[String: Any]] = []

        for section in sections {
            let items = lineItems(section)
            guard !items.isEmpty else { continue }

            // Section header (DescriptionOnly)
            lines.append([
                "DetailType": "DescriptionOnly",
                "Description": "--- \(sectionName(section)) ---",
            ])

            // Line items
            for item in items {
                let lineDict: [String: Any] = [
                    "DetailType": "SalesItemLineDetail",
                    "Amount": NSDecimalNumber(decimal: lineTotal(item)).doubleValue,
                    "Description": itemDescription(item),
                    "SalesItemLineDetail": [
                        "Qty": NSDecimalNumber(decimal: quantity(item)).doubleValue,
                        "UnitPrice": NSDecimalNumber(decimal: unitPrice(item)).doubleValue,
                        "ItemRef": ["value": qbItemRef(item) ?? "1"], // Default to "Services" item if no QB ref
                    ] as [String: Any],
                ]
                _ = lineDict // silence unused warning
                lines.append(lineDict)
            }

            // Section subtotal
            lines.append([
                "DetailType": "SubTotalLineDetail",
                "SubTotalLineDetail": [:] as [String: Any],
            ])
        }

        return lines
    }

    // MARK: - Helpers

    private func mapPaymentMethod(_ method: PaymentMethod) -> String {
        switch method {
        case .cash: "Cash"
        case .check: "Check"
        case .card: "Credit Card"
        case .ach: "EFT"
        case .zelle, .venmo: "Other"
        case .financing: "Other"
        case .other: "Other"
        }
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
