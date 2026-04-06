import Foundation

// MARK: - Shared Data Reader (Widget Side)
// Reads the WidgetSnapshot that the main app writes to App Group UserDefaults.

enum WidgetAppGroup {
    static let identifier = "group.com.mmcc.app"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: identifier)!
    }

    static func readSnapshot() -> WidgetSnapshot? {
        guard let data = sharedDefaults.data(forKey: WidgetSnapshot.storageKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return nil }
        return snapshot
    }
}

// Duplicated here because widget extension can't import main app target.
// Keep in sync with Services/WidgetDataService.swift.

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
