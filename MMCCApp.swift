import SwiftData
import SwiftUI
import Foundation
import WidgetKit

@main
struct MMCCApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            QBServiceProviderView {
                ContentView()
            }
        }
        .modelContainer(for: [
            BusinessProfile.self,
            Customer.self,
            Proposal.self,
            ProposalSection.self,
            ProposalLineItem.self,
            Invoice.self,
            InvoiceSection.self,
            InvoiceLineItem.self,
            Payment.self,
            JobTemplate.self,
            TemplateSection.self,
            TemplateItem.self,
            SavedItem.self,
            SyncQueueItem.self,
        ])
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                WidgetSyncHelper.shared.syncPending()
            }
        }
    }
}

// MARK: - QB Service Provider

/// Initializes QuickBooks services once the ModelContext is available,
/// injects them into the environment, handles OAuth callbacks and queue processing.
private struct QBServiceProviderView<Content: View>: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var authManager: QBAuthManager?
    @State private var syncCoordinator: SyncCoordinator?
    @State private var subscriptionManager: SubscriptionManager?
    @State private var proTierService: ProTierService?

    let content: () -> Content

    var body: some View {
        Group {
            if let authManager, let syncCoordinator, let subscriptionManager, let proTierService {
                content()
                    .environment(authManager)
                    .environment(syncCoordinator)
                    .environment(subscriptionManager)
                    .environment(proTierService)
            } else {
                ZStack {
                    Color.mmccNavy.ignoresSafeArea()
                    ProgressView()
                        .tint(Color.mmccAmber)
                }
            }
        }
        .task {
            guard authManager == nil else { return }

            // StoreKit
            let subManager = SubscriptionManager()
            let tierService = ProTierService(subscriptionManager: subManager, modelContext: modelContext)
            await subManager.start()
            subscriptionManager = subManager
            proTierService = tierService

            // QuickBooks
            let auth = QBAuthManager(modelContext: modelContext)
            let apiClient = QBAPIClient(authManager: auth)
            let syncService = QBSyncService(apiClient: apiClient, modelContext: modelContext)
            let coordinator = SyncCoordinator(syncService: syncService, authManager: auth, modelContext: modelContext)
            coordinator.startMonitoring()
            authManager = auth
            syncCoordinator = coordinator
        }
        .onOpenURL { url in
            // OAuth callback is handled internally by ASWebAuthenticationSession,
            // but this catches any stray deep links to the mmcc:// scheme.
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active, let coordinator = syncCoordinator {
                Task { await coordinator.processQueue() }
            }
        }
    }
}

// MARK: - Widget Sync Helper
// Collects model data and writes to shared App Group for widgets.

@MainActor
final class WidgetSyncHelper {
    static let shared = WidgetSyncHelper()
    private var pendingProposals: [Proposal] = []
    private var pendingInvoices: [Invoice] = []
    private var dirty = false

    func update(proposals: [Proposal], invoices: [Invoice]) {
        pendingProposals = proposals
        pendingInvoices = invoices
        dirty = true
    }

    func syncPending() {
        guard dirty else { return }
        WidgetDataService.updateWidgetData(proposals: pendingProposals, invoices: pendingInvoices)
        dirty = false
    }

    func syncNow(proposals: [Proposal], invoices: [Invoice]) {
        WidgetDataService.updateWidgetData(proposals: proposals, invoices: invoices)
    }
}
