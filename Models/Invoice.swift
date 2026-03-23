import Foundation
import SwiftData

@Model
final class Invoice {
    var id: UUID = UUID()
    var number: Int = 0
    var status: InvoiceStatus = InvoiceStatus.draft
    var customer: Customer?
    var jobAddress: String = ""
    var waterway: String = ""
    var paymentTerms: PaymentTerms = PaymentTerms.dueOnReceipt
    var dueDate: Date?
    var taxRate: Decimal = 0.0
    var notes: String = ""
    var terms: String = ""
    var sourceProposalID: UUID?
    var qbInvoiceID: String?
    @Relationship(deleteRule: .cascade, inverse: \InvoiceSection.invoice) var sections: [InvoiceSection]?
    @Relationship(deleteRule: .cascade, inverse: \Payment.invoice) var payments: [Payment]?
    @Attribute(.externalStorage) var sentPDFData: Data?
    var createdAt: Date = Date.now
    var sentAt: Date?
    init() {}
    var sortedSections: [InvoiceSection] { (sections ?? []).sorted { $0.sortOrder < $1.sortOrder } }
    var subtotal: Decimal { (sections ?? []).reduce(.zero) { $0 + $1.subtotal } }
    var taxAmount: Decimal { taxRate > 0 ? subtotal * (taxRate / 100) : 0 }
    var grandTotal: Decimal { subtotal + taxAmount }
    var totalPaid: Decimal { (payments ?? []).reduce(.zero) { $0 + $1.amount } }
    var balanceDue: Decimal { grandTotal - totalPaid }
    var isOverdue: Bool { guard let dueDate, status == .sent || status == .partiallyPaid else { return false }; return dueDate < .now }
}

@Model
final class InvoiceSection {
    var id: UUID = UUID()
    var name: String = ""
    var sortOrder: Int = 0
    var invoice: Invoice?
    @Relationship(deleteRule: .cascade, inverse: \InvoiceLineItem.section) var lineItems: [InvoiceLineItem]?
    init(name: String = "Items", sortOrder: Int = 0) { self.name = name; self.sortOrder = sortOrder }
    var sortedLineItems: [InvoiceLineItem] { (lineItems ?? []).sorted { $0.sortOrder < $1.sortOrder } }
    var subtotal: Decimal { (lineItems ?? []).reduce(.zero) { $0 + $1.lineTotal } }
}

@Model
final class InvoiceLineItem {
    var id: UUID = UUID()
    var itemDescription: String = ""
    var quantity: Decimal = 1
    var unitPrice: Decimal = 0
    var unit: String = "ea"
    var sortOrder: Int = 0
    var section: InvoiceSection?
    var qbItemRef: String?
    init() {}
    var lineTotal: Decimal { quantity * unitPrice }
}

@Model
final class Payment {
    var id: UUID = UUID()
    var amount: Decimal = 0
    var method: PaymentMethod = PaymentMethod.other
    var date: Date = Date.now
    var note: String = ""
    var isMilestone: Bool = false
    var milestoneLabel: String = ""
    var invoice: Invoice?
    var qbPaymentID: String?
    init() {}
    init(amount: Decimal, method: PaymentMethod) { self.amount = amount; self.method = method }
}
