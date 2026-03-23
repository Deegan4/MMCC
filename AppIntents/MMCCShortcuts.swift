import AppIntents
import SwiftUI

// MARK: - App Shortcuts Provider

struct MMCCShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenProposalCountIntent(),
            phrases: [
                "How many open proposals do I have in \(.applicationName)",
                "Open proposals in \(.applicationName)",
                "Show my \(.applicationName) proposals",
            ],
            shortTitle: "Open Proposals",
            systemImageName: "doc.text"
        )

        AppShortcut(
            intent: TotalUnpaidIntent(),
            phrases: [
                "How much is unpaid in \(.applicationName)",
                "Unpaid invoices in \(.applicationName)",
                "What do customers owe in \(.applicationName)",
            ],
            shortTitle: "Unpaid Total",
            systemImageName: "dollarsign.circle"
        )

        AppShortcut(
            intent: CreateProposalIntent(),
            phrases: [
                "Create a new estimate in \(.applicationName)",
                "New proposal in \(.applicationName)",
                "Start a dock estimate in \(.applicationName)",
            ],
            shortTitle: "New Proposal",
            systemImageName: "plus.circle"
        )
    }
}

// MARK: - Open Proposal Count

struct OpenProposalCountIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Proposal Count"
    static let description: IntentDescription = "Shows how many proposals are currently open (draft, sent, or accepted)."
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let snapshot = WidgetDataService.readSnapshot()
        let count = snapshot?.openProposalCount ?? 0
        let total = snapshot?.totalJobs ?? 0
        return .result(
            dialog: "You have \(count) open proposal\(count == 1 ? "" : "s") out of \(total) total."
        )
    }
}

// MARK: - Total Unpaid

struct TotalUnpaidIntent: AppIntent {
    static let title: LocalizedStringResource = "Unpaid Invoice Total"
    static let description: IntentDescription = "Shows the total amount of unpaid invoices."
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let snapshot = WidgetDataService.readSnapshot()
        let unpaid = snapshot?.unpaidTotal ?? "$0.00"
        let overdue = snapshot?.overdueCount ?? 0
        var message = "You have \(unpaid) in unpaid invoices."
        if overdue > 0 {
            message += " \(overdue) \(overdue == 1 ? "is" : "are") overdue."
        }
        return .result(dialog: "\(message)")
    }
}

// MARK: - Create Proposal (opens app)

struct CreateProposalIntent: AppIntent {
    static let title: LocalizedStringResource = "Create New Proposal"
    static let description: IntentDescription = "Opens MMCC to create a new proposal."
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NotificationCenter.default.post(name: .createProposalFromIntent, object: nil)
        }
        return .result()
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let createProposalFromIntent = Notification.Name("com.mmcc.createProposalFromIntent")
}
