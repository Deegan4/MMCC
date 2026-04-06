import Foundation
import SwiftData

@Model
final class Customer {
    var id: UUID = UUID()
    var name: String = ""
    var phone: String = ""
    var email: String = ""
    var address: String = ""
    var notes: String = ""
    var propertyType: PropertyType?
    var existingSystemType: SystemType?
    var squareFootage: Int?
    var qbCustomerID: String?
    @Relationship(deleteRule: .cascade, inverse: \Proposal.customer) var proposals: [Proposal]?
    @Relationship(deleteRule: .cascade, inverse: \Invoice.customer) var invoices: [Invoice]?
    var createdAt: Date = Date.now
    init(name: String = "") { self.name = name }
    var unpaidInvoiceTotal: Decimal {
        (invoices ?? []).filter { $0.status == .sent || $0.status == .overdue || $0.status == .partiallyPaid }
            .reduce(Decimal.zero) { $0 + $1.balanceDue }
    }
}
