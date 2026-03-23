# MMCC Project Overview

## What
iOS 26 SwiftUI app for **boat dock builders and marine contractors**. Fastest estimate app for the niche — 60-second bids for docks, seawalls, pilings, boat lifts. Syncs to QuickBooks Online.

## Tech Stack
- iOS 26+, SwiftUI, Liquid Glass, Swift 6 strict concurrency
- SwiftData + CloudKit (offline-first, auto-save)
- XcodeGen (`project.yml`) for project generation
- Bundle ID: `com.mmcc.app`, Team: `A6H72TGWNL`

## Architecture
- **Models:** Estimate/Invoice/Customer/JobTemplate/SavedItem/BusinessProfile (all SwiftData @Model, CloudKit-safe optional relationships)
- **Services:** PDFGenerator, WidgetDataService
- **QuickBooks:** QBAuthManager → QBAPIClient → QBSyncService → SyncCoordinator (all iOS-side complete, Cloudflare Worker deferred)
- **Views:** Dashboard, Estimates (list/detail/section), Invoices (list/detail/payments), Library, Settings, Onboarding

## Build Status (as of 2026-03-21)
- **Week 1-2: COMPLETE** — All core features (estimates, invoices, PDF, dashboard, SavedItem CRUD, freeform estimates, QB sync iOS layer)
- **Week 3-4: NOT STARTED** — Cloudflare Worker, StoreKit 2 subscriptions, free tier limits, Intuit App Store submission

## Key Patterns
- CloudKit-safe: optional arrays, nil-check-before-append, nil-coalescing iteration
- `#Predicate` requires local `let` for captured values (can't capture object properties)
- Codable `Type` property conflicts with Swift metatype — use CodingKeys rename
- QB sync is push-on-action (ADR-004): fires in `markSent()` and `savePayment()`, not continuous
- Offline queue: SyncQueueItem FIFO, max 3 retries, auto-processes on connectivity restored

## Code Signing
- `DEVELOPMENT_TEAM: A6H72TGWNL` in project.yml
- Do NOT set `CODE_SIGNING_REQUIRED: NO` — breaks device builds
- One cert is revoked (`75EE3903...`), the valid one (`C24EE4B7...`) works fine
