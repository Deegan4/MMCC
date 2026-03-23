import Foundation
import Observation
import SwiftData

/// Enforces free-tier limits using SwiftData counts + SubscriptionManager state.
/// Calendar-month reset for proposals and invoices.
@Observable
@MainActor
final class ProTierService {
    private let subscriptionManager: SubscriptionManager
    private let modelContext: ModelContext

    init(subscriptionManager: SubscriptionManager, modelContext: ModelContext) {
        self.subscriptionManager = subscriptionManager
        self.modelContext = modelContext
    }

    var tier: SubscriptionTier { subscriptionManager.tier }
    var isPro: Bool { subscriptionManager.isPro }

    // MARK: - Proposal Limits

    func canCreateProposal() -> Bool {
        guard let limit = tier.proposalLimit else { return true }
        return proposalsThisMonth() < limit
    }

    func remainingProposals() -> Int? {
        guard let limit = tier.proposalLimit else { return nil }
        return max(0, limit - proposalsThisMonth())
    }

    private func proposalsThisMonth() -> Int {
        let startOfMonth = Calendar.current.startOfMonth(for: Date.now)
        let start = startOfMonth
        var descriptor = FetchDescriptor<Proposal>(predicate: #Predicate { $0.createdAt >= start })
        descriptor.propertiesToFetch = []
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Invoice Limits

    func canCreateInvoice() -> Bool {
        guard let limit = tier.invoiceLimit else { return true }
        return invoicesThisMonth() < limit
    }

    func remainingInvoices() -> Int? {
        guard let limit = tier.invoiceLimit else { return nil }
        return max(0, limit - invoicesThisMonth())
    }

    private func invoicesThisMonth() -> Int {
        let startOfMonth = Calendar.current.startOfMonth(for: Date.now)
        let start = startOfMonth
        var descriptor = FetchDescriptor<Invoice>(predicate: #Predicate { $0.createdAt >= start })
        descriptor.propertiesToFetch = []
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Customer Limits

    func canAddCustomer() -> Bool {
        guard let limit = tier.customerLimit else { return true }
        return totalCustomers() < limit
    }

    func remainingCustomers() -> Int? {
        guard let limit = tier.customerLimit else { return nil }
        return max(0, limit - totalCustomers())
    }

    private func totalCustomers() -> Int {
        let descriptor = FetchDescriptor<Customer>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Saved Item Limits

    func canAddSavedItem() -> Bool {
        guard let limit = tier.savedItemLimit else { return true }
        return totalSavedItems() < limit
    }

    func remainingSavedItems() -> Int? {
        guard let limit = tier.savedItemLimit else { return nil }
        return max(0, limit - totalSavedItems())
    }

    private func totalSavedItems() -> Int {
        let descriptor = FetchDescriptor<SavedItem>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Template Limits

    func canAddTemplate() -> Bool {
        guard let limit = tier.templateLimit else { return true }
        return userTemplates() < limit
    }

    private func userTemplates() -> Int {
        let descriptor = FetchDescriptor<JobTemplate>(predicate: #Predicate { !$0.isSystemTemplate })
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Feature Gates

    func canSyncToQuickBooks() -> Bool { tier.canSyncQuickBooks }
    func canRemoveWatermark() -> Bool { tier.canRemoveWatermark }
    func canExportCSV() -> Bool { tier.canExportCSV }

    // MARK: - Formatted Limit Strings

    func proposalLimitText() -> String? {
        guard let remaining = remainingProposals(), let limit = tier.proposalLimit else { return nil }
        let used = limit - remaining
        return "\(used)/\(limit) proposals this month"
    }

    func invoiceLimitText() -> String? {
        guard let remaining = remainingInvoices(), let limit = tier.invoiceLimit else { return nil }
        let used = limit - remaining
        return "\(used)/\(limit) invoices this month"
    }
}

// MARK: - Calendar Helper

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
