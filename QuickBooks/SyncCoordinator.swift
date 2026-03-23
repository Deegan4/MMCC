import Foundation
import Network
import SwiftData

// MARK: - SyncCoordinator

@Observable
@MainActor
final class SyncCoordinator {
    private let syncService: QBSyncService
    private let authManager: QBAuthManager
    private let modelContext: ModelContext
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.mmcc.networkMonitor")

    private(set) var isSyncing = false
    private(set) var pendingQueueCount = 0
    private(set) var lastSyncError: String?
    private(set) var isOnline = true

    init(syncService: QBSyncService, authManager: QBAuthManager, modelContext: ModelContext) {
        self.syncService = syncService
        self.authManager = authManager
        self.modelContext = modelContext
        updateQueueCount()
    }

    // MARK: - Network Monitoring

    func startMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let wasOffline = !self.isOnline
                self.isOnline = path.status == .satisfied

                // When coming back online with a non-empty queue, process it
                if wasOffline, self.isOnline, self.pendingQueueCount > 0, self.authManager.isConnected {
                    await self.processQueue()
                }
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }

    func stopMonitoring() {
        networkMonitor.cancel()
    }

    // MARK: - Sync Triggers (called from UI)

    func syncProposal(_ proposal: Proposal) async {
        guard authManager.isConnected, let realmID = authManager.realmID else { return }

        if isOnline {
            isSyncing = true
            defer { isSyncing = false }
            do {
                try await syncService.pushProposal(proposal, realmID: realmID)
                lastSyncError = nil
            } catch {
                handleSyncError(error, entityType: .proposal, entityID: proposal.id,
                                action: proposal.qbProposalID == nil ? .create : .update)
            }
        } else {
            enqueue(entityType: .proposal, entityID: proposal.id,
                    action: proposal.qbProposalID == nil ? .create : .update)
        }
    }

    func syncInvoice(_ invoice: Invoice) async {
        guard authManager.isConnected, let realmID = authManager.realmID else { return }

        if isOnline {
            isSyncing = true
            defer { isSyncing = false }
            do {
                try await syncService.pushInvoice(invoice, realmID: realmID)
                lastSyncError = nil
            } catch {
                handleSyncError(error, entityType: .invoice, entityID: invoice.id,
                                action: invoice.qbInvoiceID == nil ? .create : .update)
            }
        } else {
            enqueue(entityType: .invoice, entityID: invoice.id,
                    action: invoice.qbInvoiceID == nil ? .create : .update)
        }
    }

    func syncPayment(_ payment: Payment, invoice: Invoice) async {
        guard authManager.isConnected, let realmID = authManager.realmID else { return }

        if isOnline {
            isSyncing = true
            defer { isSyncing = false }
            do {
                try await syncService.pushPayment(payment, invoice: invoice, realmID: realmID)
                lastSyncError = nil
            } catch {
                handleSyncError(error, entityType: .payment, entityID: payment.id, action: .create)
            }
        } else {
            enqueue(entityType: .payment, entityID: payment.id, action: .create)
        }
    }

    func syncCustomer(_ customer: Customer) async {
        guard authManager.isConnected, let realmID = authManager.realmID else { return }

        if isOnline {
            isSyncing = true
            defer { isSyncing = false }
            do {
                try await syncService.pushCustomer(customer, realmID: realmID)
                lastSyncError = nil
            } catch {
                handleSyncError(error, entityType: .customer, entityID: customer.id,
                                action: customer.qbCustomerID == nil ? .create : .update)
            }
        } else {
            enqueue(entityType: .customer, entityID: customer.id,
                    action: customer.qbCustomerID == nil ? .create : .update)
        }
    }

    // MARK: - Queue Processing

    func processQueue() async {
        guard authManager.isConnected, isOnline else { return }
        guard let realmID = authManager.realmID else { return }

        let descriptor = FetchDescriptor<SyncQueueItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        guard let queueItems = try? modelContext.fetch(descriptor), !queueItems.isEmpty else { return }

        isSyncing = true
        defer {
            isSyncing = false
            updateQueueCount()
        }

        for item in queueItems {
            guard item.canRetry else { continue }

            do {
                try await processQueueItem(item, realmID: realmID)
                modelContext.delete(item)
            } catch let error as QBAPIError {
                item.retryCount += 1
                item.lastError = error.localizedDescription

                // Stop processing on rate limit — will resume later
                if case .rateLimited = error { break }
            } catch {
                item.retryCount += 1
                item.lastError = error.localizedDescription
            }
        }

        try? modelContext.save()
    }

    // MARK: - Private Helpers

    private func processQueueItem(_ item: SyncQueueItem, realmID: String) async throws {
        let entityID = item.entityID

        switch item.entityType {
        case .proposal:
            let descriptor = FetchDescriptor<Proposal>(predicate: #Predicate { $0.id == entityID })
            guard let proposal = try modelContext.fetch(descriptor).first else {
                modelContext.delete(item)
                return
            }
            try await syncService.pushProposal(proposal, realmID: realmID)

        case .invoice:
            let descriptor = FetchDescriptor<Invoice>(predicate: #Predicate { $0.id == entityID })
            guard let invoice = try modelContext.fetch(descriptor).first else {
                modelContext.delete(item)
                return
            }
            try await syncService.pushInvoice(invoice, realmID: realmID)

        case .payment:
            let descriptor = FetchDescriptor<Payment>(predicate: #Predicate { $0.id == entityID })
            guard let payment = try modelContext.fetch(descriptor).first,
                  let invoice = payment.invoice
            else {
                modelContext.delete(item)
                return
            }
            try await syncService.pushPayment(payment, invoice: invoice, realmID: realmID)

        case .customer:
            let descriptor = FetchDescriptor<Customer>(predicate: #Predicate { $0.id == entityID })
            guard let customer = try modelContext.fetch(descriptor).first else {
                modelContext.delete(item)
                return
            }
            try await syncService.pushCustomer(customer, realmID: realmID)
        }
    }

    private func handleSyncError(_ error: Error, entityType: SyncEntityType, entityID: UUID, action: SyncAction) {
        if let apiError = error as? QBAPIError {
            switch apiError {
            case .networkUnavailable:
                enqueue(entityType: entityType, entityID: entityID, action: action)
                return
            case .rateLimited:
                enqueue(entityType: entityType, entityID: entityID, action: action)
                lastSyncError = apiError.localizedDescription
                return
            default:
                lastSyncError = apiError.localizedDescription
            }
        } else if let authError = error as? QBAuthError {
            lastSyncError = authError.localizedDescription
        } else {
            lastSyncError = error.localizedDescription
            enqueue(entityType: entityType, entityID: entityID, action: action)
        }
    }

    private func enqueue(entityType: SyncEntityType, entityID: UUID, action: SyncAction) {
        let item = SyncQueueItem(entityType: entityType, entityID: entityID, action: action)
        modelContext.insert(item)
        try? modelContext.save()
        updateQueueCount()
    }

    private func updateQueueCount() {
        let descriptor = FetchDescriptor<SyncQueueItem>()
        pendingQueueCount = (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}
