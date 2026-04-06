import Foundation
import SwiftData

@Model
final class Proposal {
    var id: UUID = UUID()
    var number: Int = 0
    var title: String = ""
    var status: ProposalStatus = ProposalStatus.draft
    var customer: Customer?
    var jobAddress: String = ""
    var systemType: SystemType?
    var serviceType: ServiceType?
    var propertyType: PropertyType?
    var markup: Decimal = 0.0
    var taxRate: Decimal = 0.0
    var notes: String = ""
    var terms: String = ""
    var validUntil: Date?
    var customField1Label: String = ""
    var customField1Value: String = ""
    var customField2Label: String = ""
    var customField2Value: String = ""
    var customFieldsExtra: [String: String] = [:]
    var sourceTemplateName: String?
    var qbProposalID: String?
    var qbDocNumber: String?
    @Relationship(deleteRule: .cascade, inverse: \ProposalSection.proposal) var sections: [ProposalSection]?
    @Attribute(.externalStorage) var sentPDFData: Data?
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var sentAt: Date?
    var acceptedAt: Date?
    init() {}
    var sortedSections: [ProposalSection] { (sections ?? []).sorted { $0.sortOrder < $1.sortOrder } }
    var subtotal: Decimal { (sections ?? []).reduce(.zero) { $0 + $1.subtotal } }
    var markupAmount: Decimal { markup > 0 ? subtotal * (markup / 100) : 0 }
    var subtotalWithMarkup: Decimal { subtotal + markupAmount }
    var taxAmount: Decimal { taxRate > 0 ? subtotalWithMarkup * (taxRate / 100) : 0 }
    var grandTotal: Decimal { subtotalWithMarkup + taxAmount }
}

@Model
final class ProposalSection {
    var id: UUID = UUID()
    var name: String = ""
    var sortOrder: Int = 0
    var permitStatus: PermitStatus = PermitStatus.none
    var permitNumber: String = ""
    var proposal: Proposal?
    @Relationship(deleteRule: .cascade, inverse: \ProposalLineItem.section) var lineItems: [ProposalLineItem]?
    init(name: String = "Items", sortOrder: Int = 0) { self.name = name; self.sortOrder = sortOrder }
    var sortedLineItems: [ProposalLineItem] { (lineItems ?? []).sorted { $0.sortOrder < $1.sortOrder } }
    var subtotal: Decimal { (lineItems ?? []).reduce(.zero) { $0 + $1.lineTotal } }
    var needsPermit: Bool { permitStatus != .none }
}

@Model
final class ProposalLineItem {
    var id: UUID = UUID()
    var itemDescription: String = ""
    var quantity: Decimal = 1
    var unitPrice: Decimal = 0
    var unit: String = "ea"
    var sortOrder: Int = 0
    var section: ProposalSection?
    var savedItemID: UUID?
    var qbItemRef: String?
    init() {}
    init(description: String, quantity: Decimal, unitPrice: Decimal, unit: String = "ea") {
        self.itemDescription = description; self.quantity = quantity; self.unitPrice = unitPrice; self.unit = unit
    }
    var lineTotal: Decimal { quantity * unitPrice }
}
