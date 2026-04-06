import Foundation
import WidgetKit

// MARK: - App Group Constants

enum AppGroup {
    static let identifier = "group.com.mmcc.app"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: identifier)!
    }
}

// MARK: - Widget Data (Shared between app and widget)

struct WidgetProposal: Codable {
    var title: String
    var customerName: String
    var amount: String
    var statusRaw: String
    var number: Int
}

struct WidgetInvoice: Codable {
    var customerName: String
    var balanceDue: String
    var statusRaw: String
    var number: Int
    var isOverdue: Bool
}

struct WidgetSnapshot: Codable {
    var openProposalCount: Int
    var unpaidTotal: String
    var totalJobs: Int
    var overdueCount: Int
    var activeProposals: [WidgetProposal]
    var unpaidInvoices: [WidgetInvoice]
    var updatedAt: Date

    static let storageKey = "widgetSnapshot"

    static var placeholder: WidgetSnapshot {
        WidgetSnapshot(
            openProposalCount: 3,
            unpaidTotal: "$12,500.00",
            totalJobs: 8,
            overdueCount: 1,
            activeProposals: [
                WidgetProposal(title: "AC Replacement", customerName: "J. Smith", amount: "$8,200", statusRaw: "sent", number: 1),
                WidgetProposal(title: "Duct Repair", customerName: "R. Davis", amount: "$4,300", statusRaw: "draft", number: 2),
            ],
            unpaidInvoices: [
                WidgetInvoice(customerName: "T. Wilson", balanceDue: "$6,500", statusRaw: "sent", number: 1, isOverdue: false),
            ],
            updatedAt: .now
        )
    }
}

// MARK: - Widget Data Writer (Main App)

enum WidgetDataService {
    static func updateWidgetData(
        proposals: [any ProposalWidgetSource],
        invoices: [any InvoiceWidgetSource]
    ) {
        let active = proposals.filter(\.isActiveForWidget)
        let unpaid = invoices.filter(\.isUnpaidForWidget)
        let unpaidTotal = unpaid.reduce(Decimal.zero) { $0 + $1.widgetBalanceDue }

        let snapshot = WidgetSnapshot(
            openProposalCount: active.count,
            unpaidTotal: unpaidTotal.formatted(.currency(code: "USD")),
            totalJobs: proposals.count,
            overdueCount: invoices.filter(\.isOverdueForWidget).count,
            activeProposals: active.prefix(5).map { prop in
                WidgetProposal(
                    title: prop.widgetTitle,
                    customerName: prop.widgetCustomerName,
                    amount: prop.widgetGrandTotal.formatted(.currency(code: "USD")),
                    statusRaw: prop.widgetStatusRaw,
                    number: prop.widgetNumber
                )
            },
            unpaidInvoices: unpaid.prefix(5).map { inv in
                WidgetInvoice(
                    customerName: inv.widgetCustomerName,
                    balanceDue: inv.widgetBalanceDue.formatted(.currency(code: "USD")),
                    statusRaw: inv.widgetStatusRaw,
                    number: inv.widgetNumber,
                    isOverdue: inv.isOverdueForWidget
                )
            },
            updatedAt: .now
        )

        if let data = try? JSONEncoder().encode(snapshot) {
            AppGroup.sharedDefaults.set(data, forKey: WidgetSnapshot.storageKey)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    static func readSnapshot() -> WidgetSnapshot? {
        guard let data = AppGroup.sharedDefaults.data(forKey: WidgetSnapshot.storageKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return nil }
        return snapshot
    }
}

// MARK: - Protocols for decoupling from SwiftData models

protocol ProposalWidgetSource {
    var isActiveForWidget: Bool { get }
    var widgetTitle: String { get }
    var widgetCustomerName: String { get }
    var widgetGrandTotal: Decimal { get }
    var widgetStatusRaw: String { get }
    var widgetNumber: Int { get }
}

protocol InvoiceWidgetSource {
    var isUnpaidForWidget: Bool { get }
    var isOverdueForWidget: Bool { get }
    var widgetCustomerName: String { get }
    var widgetBalanceDue: Decimal { get }
    var widgetStatusRaw: String { get }
    var widgetNumber: Int { get }
}

// MARK: - SwiftData Model Conformance

extension Proposal: ProposalWidgetSource {
    var isActiveForWidget: Bool { status.isActive }
    var widgetTitle: String { title.isEmpty ? "Untitled" : title }
    var widgetCustomerName: String { customer?.name ?? "No Customer" }
    var widgetGrandTotal: Decimal { grandTotal }
    var widgetStatusRaw: String { status.rawValue }
    var widgetNumber: Int { number }
}

extension Invoice: InvoiceWidgetSource {
    var isUnpaidForWidget: Bool { status == .sent || status == .partiallyPaid || status == .overdue }
    var isOverdueForWidget: Bool { isOverdue }
    var widgetCustomerName: String { customer?.name ?? "No Customer" }
    var widgetBalanceDue: Decimal { balanceDue }
    var widgetStatusRaw: String { status.rawValue }
    var widgetNumber: Int { number }
}
