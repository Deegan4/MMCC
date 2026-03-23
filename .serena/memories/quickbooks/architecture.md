# QuickBooks Integration Architecture

## Layer Stack (bottom-up)
```
UI (SettingsView, EstimateDetailView, InvoiceDetailView, DashboardView)
  ↕ @Environment
SyncCoordinator — queue orchestration, NWPathMonitor, processes on foreground
  ↕
QBSyncService — model→JSON mapping, section→DescriptionOnly conversion
  ↕
QBAPIClient — actor, Bearer auth, 401 retry, 429 rate limit, 5xx propagation
  ↕
QBAuthManager — ASWebAuthenticationSession OAuth, token storage in BusinessProfile
  ↕
Cloudflare Worker — DEFERRED (token exchange + refresh, holds client secret)
```

## Files
- `QuickBooks/QBAuthManager.swift` — @Observable @MainActor, startOAuthFlow(), refreshTokenIfNeeded(), disconnect()
- `QuickBooks/QBAPIClient.swift` — actor, get/post/query methods, executeRequest with retry
- `QuickBooks/QBSyncService.swift` — pushCustomer/Estimate/Invoice/Payment, pullCustomers/Items/TaxRates
- `QuickBooks/QBModels.swift` — QBCustomerDTO, QBItemDTO, QBTaxRateDTO, QBCreatedEntity, QBLine, QBRef
- `QuickBooks/SyncCoordinator.swift` — syncEstimate/Invoice/Payment/Customer, processQueue(), startMonitoring()

## Wiring (MMCCApp.swift)
- QBServiceProviderView wraps ContentView
- Initializes services in `.task {}` when modelContext is available
- Passes QBAuthManager and SyncCoordinator via `.environment()`
- `.onOpenURL` for OAuth callback scheme `mmcc://`
- Processes queue on `.active` scenePhase

## Section Mapping (QB has no sections)
Each MMCC section becomes:
1. DescriptionOnly line: `"--- Pilings ---"`
2. SalesItemLineDetail lines (qty, unit price, item ref)
3. SubTotalLineDetail line

## Sync Triggers (ADR-004: push-on-action)
- EstimateDetailView.markSent() → syncCoordinator.syncEstimate()
- InvoiceDetailView.markSent() → syncCoordinator.syncInvoice()
- RecordPaymentSheet.savePayment() → syncCoordinator.syncPayment()

## Offline Queue
- SyncQueueItem model (entityType, entityID, action, retryCount, maxRetries=3)
- Enqueued on: network failure, rate limiting, generic errors
- Processed: on connectivity restored (NWPathMonitor), on app foreground, manual "Sync Now"
- Items deleted from queue on success; retryCount incremented on failure

## TODO Before Live
1. Deploy Cloudflare Worker with QB_CLIENT_ID + QB_CLIENT_SECRET env vars
2. Replace QBAuthManager.clientID and workerBaseURL placeholders
3. Register redirect URI `mmcc://oauth-callback` in Intuit Developer Console
4. Test full flow with Intuit sandbox company
