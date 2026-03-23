---
name: sync-check
description: Verify QuickBooks sync chain integrity after code changes - checks SyncCoordinator queue, QBSyncService mapping, QBAPIClient retry logic
---

# QuickBooks Sync Health Check

Verify the entire QuickBooks sync chain is intact. Run this after any changes to QuickBooks/, Models/, or sync-related views.

## Files to Check

Read these files in the QuickBooks/ directory:
1. `QBAuthManager.swift` — OAuth token management
2. `QBAPIClient.swift` — HTTP actor, auth headers, retry logic
3. `QBSyncService.swift` — Model-to-DTO mapping
4. `SyncCoordinator.swift` — Queue orchestration, NWPathMonitor
5. `QBModels.swift` — Codable DTOs for Intuit API

## Verification Checklist

### 1. Push-on-Action Triggers (ADR-004)
- Search for `markSent()` in proposal/invoice views — must trigger sync
- Search for `savePayment()` — must trigger sync
- Sync must NOT fire on every keystroke or field change
- Verify SyncCoordinator is called, not QBSyncService directly

### 2. Offline Queue (ADR-006)
- `SyncQueueItem` model exists with FIFO ordering
- Max retry count is 3
- Queue auto-processes on:
  - Network connectivity restored (NWPathMonitor)
  - App foregrounding (scene phase change)
- Failed items are re-enqueued, not dropped

### 3. Auth Chain
- QBAuthManager stores tokens in BusinessProfile (not Keychain)
- Token refresh has 5-minute buffer before expiry
- 401 response triggers token refresh then retry (once)
- Refresh token expiry (100 days) triggers re-auth flow
- ASWebAuthenticationSession for OAuth flow

### 4. API Client
- QBAPIClient is an `actor` (thread safety)
- Bearer token in Authorization header
- 429 rate limiting handled (backoff or queue)
- 5xx errors propagated, not silently swallowed

### 5. DTO Mapping
- QBModels use dynamic CodingKey for PascalCase Intuit responses
- Section → DescriptionOnly + SubTotalLineDetail mapping (QB has no native sections)
- Customer auto-pushed if not yet synced before estimate/invoice push

### 6. UI Integration
- SettingsView has connect/disconnect QB flow
- Detail views show sync indicator
- Dashboard shows: pending count badge, sync spinner, error dot

## Output Format

```
## QB Sync Health Check

- [x] Push-on-action: markSent() triggers sync
- [x] Push-on-action: savePayment() triggers sync
- [ ] ISSUE: Queue retry count is 5, should be 3 (SyncCoordinator.swift:42)
- [x] Auth: 5-min refresh buffer
...

### Result: HEALTHY / X ISSUES FOUND
```
