# Claude Code Instructions for MMCC

## Project Context
You are building MMCC, an iOS 26 SwiftUI app for **boat dock builders and marine contractors**. This is a niche app — not generic contracting. Every template, saved item, and UI decision caters to people who build docks, seawalls, install pilings, boat lifts, and do marine construction.

## Core Principles
1. **Speed is the feature.** Target: 60 seconds to send a professional estimate from a template.
2. **Auto-save everything.** No save buttons. SwiftData persists every mutation.
3. **Offline-first.** Works in marinas with no signal, on barges, at remote waterfront properties.
4. **Liquid Glass.** iOS 26 design. `.glassEffect()` on controls/navigation only, never content.
5. **Marine-specific.** Seed data, templates, item library, section names — all marine construction. Pilings, decking, seawalls, lifts, permits, dredging. Not plumbing, not electrical, not general.
6. **QB companion, not replacement.** Syncs to QuickBooks. Doesn't try to be an accounting app.

## Domain Knowledge — Marine Construction

### Common Job Types (these are the seed templates)
- **Residential dock build** — pilings, stringers, decking, cleats, bumpers, lighting, permits
- **Seawall new construction** — vinyl/concrete/steel sheet pile, cap, backfill, tie-backs, permits
- **Seawall repair** — crack repair, panel replacement, cap repair, erosion fill
- **Boat lift install** — lift unit, pilings/cradle, electrical, remote control
- **Dock repair/rebuild** — piling replacement, decking replacement, structural repair
- **Boathouse construction** — frame, roof, lift integration, electrical, lighting
- **Rip rap / rock revetment** — boulders, filter fabric, grading, erosion control
- **Piling install/replacement** — driven, jetted, or drilled pilings
- **Dock accessories** — fish cleaning station, kayak launch, PWC lift, dock box, lighting

### Common Materials & Pricing (Florida 2025-2026, residential)
- Pressure-treated wood pilings (10-12" dia): $20-40/linear foot installed
- Composite decking (Trex, Azek): $12-25/sqft installed
- Pressure-treated decking: $8-15/sqft installed
- Aluminum dock framing: $30-50/sqft
- Vinyl seawall sheet piling: $700-1,200/linear foot (SW Florida)
- Concrete seawall: $200-800/linear foot
- Boat lift (10K lb capacity): $8,000-15,000 installed
- Boat lift (20K lb capacity): $12,000-22,000 installed
- Marine electrical (shore power, dock lighting): $2,000-8,000
- Permits (dock): $200-1,500 depending on county
- Permits (seawall): $500-3,000+ depending on scope
- Engineering plans: $2,000-5,000
- Environmental survey: $1,000-3,000

### Estimate Section Names (marine-specific)
Instead of generic "Labor, Materials, Subcontractor":
- **Pilings** — all piling-related work and materials
- **Framing & Structure** — stringers, joists, bracing
- **Decking** — deck boards, fasteners, trim
- **Seawall** — sheet pile, cap, tie-backs, backfill
- **Boat Lift** — lift unit, cradle, motor, remote
- **Electrical** — shore power, lighting, lift power
- **Accessories** — cleats, bumpers, ladders, dock boxes, fish stations
- **Permits & Engineering** — county permits, DEP permits, engineering plans, surveys
- **Site Work** — demolition, debris removal, dredging, erosion control
- **Labor** — installation labor not captured in material line items

## Technical Rules

### SwiftData + CloudKit (CRITICAL)
- All models use `@Model` macro
- **NO `@Attribute(.unique)`** on any field — CloudKit does not support unique constraints
- **All relationship arrays must be optional** (`[Type]?` not `[Type]` or `[Type] = []`) — CloudKit requires optional relationships
- Use nil-coalescing pattern for relationship access: `(sections ?? [])`, `(lineItems ?? [])`
- Use nil-check-before-append pattern: `if model.items == nil { model.items = [] }; model.items?.append(item)`
- `@Relationship` with `.cascade` delete rules where appropriate
- ModelContainer with CloudKit container in App entry point
- Use `try? modelContext.save()` after critical insertions (e.g. onboarding) to ensure @Query picks up changes

### SwiftUI + Liquid Glass
- Target iOS 26+ only. No backward compatibility.
- Native TabView (auto Liquid Glass tab bar)
- `.glassEffect(in: .rect(cornerRadius: 14))` on dashboard cards, list cards, floating controls
- `.tint(Color.mmccAmber)` on primary CTAs — NOT solid `.background()` fills
- Sheets: `.sheet()` + `.presentationDetents()` — let iOS 26 handle glass background
- NO `.glassEffect()` on: List rows inside ScrollView content, Form fields, Text content
- Test all appearance modes: Light, Dark, Increased Contrast

### Brand Theme (BrandTheme.swift)
- Dark navy canvas: `Color.mmccNavy` (#122030), `.mmccNavyLight`, `.mmccNavyMid`
- Amber accent: `Color.mmccAmber` (from asset catalog)
- Status colors: `.statusDraft`, `.statusSent`, `.statusAccepted`, `.statusDeclined`, `.statusInvoiced`, `.statusOverdue`, `.statusPaid`, `.statusPartial`
- Reusable components: `StatusBadge`, `SectionHeader`, `FilterChip`, `StatCard`, `QuickActionButton`, `EmptyCard`
- When using status colors in ternary expressions with `.foregroundStyle()`, prefix with `Color.` explicitly (e.g. `Color.statusOverdue`) to avoid ShapeStyle inference failures
- `.cardBackground(cornerRadius:)` modifier for dark translucent cards on navy backgrounds

### PDF Generation
- HTML → PDF via `UIMarkupTextPrintFormatter` + `UIPrintPageRenderer`
- Marine-professional template with MMCC amber branding (#AF6118)
- `PDFGenerator.generateProposalPDF()` and `PDFGenerator.generateInvoicePDF()` static methods
- Share via `ShareSheet` (UIActivityViewController wrapper) or `SendToCustomerSheet` (pre-filled email/iMessage)
- Free tier: "Powered by MMCC" footer
- Pro: contractor's logo, no watermark

### QuickBooks Integration (iOS LAYER COMPLETE — WORKER DEFERRED)
- **QBAuthManager** — OAuth 2.0 via ASWebAuthenticationSession, token storage in BusinessProfile, silent refresh (5-min buffer), re-auth on refresh token expiry (100 days)
- **QBAPIClient** — actor for thread-safe HTTP. Handles Bearer auth, 401 retry with token refresh, 429 rate limiting, 5xx error propagation
- **QBSyncService** — Model-to-JSON mapping per entity. Section→DescriptionOnly+SubTotalLineDetail mapping for estimates/invoices (QB has no native sections). Auto-pushes customer if not yet synced.
- **SyncCoordinator** — Orchestrates sync triggers, NWPathMonitor for connectivity, SyncQueueItem FIFO queue with max 3 retries, auto-processes queue on connectivity restored and app foregrounding
- **QBModels** — Codable DTOs for Intuit API (QBCustomerDTO, QBItemDTO, QBTaxRateDTO, QBCreatedEntity). Dynamic CodingKey for PascalCase Intuit responses.
- **Push-on-action (ADR-004):** Sync fires in `markSent()` (estimates, invoices) and `savePayment()`. Not on every keystroke.
- **Offline queue (ADR-006):** SyncQueueItem model, FIFO, max 3 retries. Enqueued automatically on network failure or rate limiting.
- **UI integration:** SettingsView has connect/disconnect flow. Detail views show "Synced to QuickBooks" indicator. Dashboard has sync badge (pending count, spinner, error dot).
- **Cloudflare Worker DEFERRED:** `QBAuthManager.workerBaseURL` is a placeholder. Worker needs 2 endpoints: `POST /token/exchange`, `POST /token/refresh`. Holds Intuit client secret.
- **TODO:** Replace `QBAuthManager.clientID` and `workerBaseURL` with real values after Worker deployment.

### StoreKit 2 (IMPLEMENTED)
- Monthly ($9.99) and annual ($79.99) with 1-week free trial
- `SubscriptionManager` — `@Observable`, `Transaction.currentEntitlements` listener, UserDefaults cache for offline
- `ProTierService` — limit enforcement via `ModelContext.fetchCount()`, calendar-month reset
- Free tier limits: 5 proposals/mo, 3 invoices/mo, 10 customers, 20 saved items, 3 custom templates
- Pro gates: QB sync, PDF watermark removal, CSV export, milestone splits, custom logo
- `PaywallView` — feature comparison grid, monthly/annual toggle, purchase + restore
- `UpgradePromptView` / `UpgradePromptBanner` — reusable limit-hit components
- StoreKit config: `MMCC/MMCC.storekit` (sandbox testing)

## Current File Structure

```
Models/          — SwiftData @Model classes
  Proposal.swift        — Proposal, ProposalSection, ProposalLineItem
  ProposalMigration.swift — Schema migration (Estimate→Proposal rename)
  Invoice.swift         — Invoice, InvoiceSection, InvoiceLineItem, Payment
  Customer.swift        — Customer (with marine waterfront metadata)
  JobTemplate.swift     — JobTemplate, TemplateSection, TemplateItem
  SavedItem.swift       — SavedItem, SyncQueueItem
  BusinessProfile.swift — BusinessProfile (includes QB token fields, Google Drive flags)

Enums/           — AppEnums.swift (ProposalStatus, InvoiceStatus, QBSyncStatus, SyncAction, SyncEntityType, marine-specific enums)

Views/
  ContentView.swift              — Root view (onboarding gate + appearance mode)
  MainTabView.swift              — 5-tab layout with amber tint
  Onboarding/OnboardingView.swift — Welcome + BusinessProfile setup + seed templates
  Dashboard/
    DashboardView.swift          — Stats, quick actions, charts, active proposals, unpaid invoices, QB sync badge, global search button
    RevenueChartView.swift       — 6-month revenue bar chart + proposal win rate ring (Swift Charts)
  Estimates/
    ProposalListView.swift       — Searchable list with status filter chips
    ProposalDetailView.swift     — Full detail + actions + Send to Customer + QB sync
    ProposalSectionView.swift    — Section editor with line items
    TemplatePickerSheet.swift    — Template selection for new proposals
    SaveAsTemplateSheet.swift    — Save proposal as reusable template
  Invoices/
    InvoiceListView.swift        — List with payment progress bars
    InvoiceDetailView.swift      — Detail + actions + Send to Customer + QB sync
  Library/
    LibraryView.swift            — Saved Items + Templates + Customers (with pro tier limits)
    SavedItemEditorSheet.swift   — SavedItem create/edit form
    SavedItemPickerSheet.swift   — SavedItem picker for adding to proposals
    TemplateDetailView.swift     — Template detail viewer
    TemplateEditorSheet.swift    — Full template builder with sections
  Settings/SettingsView.swift    — Business profile, QB connect, Google Drive, subscription, appearance
  Settings/PaywallView.swift     — Pro subscription paywall with feature grid + purchase
  Components/
    BrandTheme.swift             — Colors, status extensions, reusable UI (StatusBadge, SectionHeader, CardBackground)
    ShareSheet.swift             — UIActivityViewController wrapper
    SendToCustomerSheet.swift    — Pre-filled email/iMessage send flow with PDF attachment
    GlobalSearchView.swift       — Federated search across proposals, invoices, customers, saved items
    CustomerPickerSheet.swift    — Customer selection/creation (with tier limit)
    UpgradePromptView.swift      — Reusable upgrade prompt + banner components
    DriveFilePickerSheet.swift   — Google Drive file browser (stubbed)

GoogleDrive/     — Google Drive integration (partially implemented)
  GoogleDriveAuthManager.swift   — OAuth 2.0 skeleton
  GoogleDriveClient.swift        — API client
  DriveModels.swift              — Codable DTOs

QuickBooks/      — QB integration layer (iOS complete, Worker deferred)
  QBAuthManager.swift            — OAuth 2.0 flow, token storage/refresh
  QBAPIClient.swift              — HTTP transport actor, auth headers, retry logic
  QBSyncService.swift            — Entity-specific model→JSON mapping + push/pull
  QBModels.swift                 — Codable DTOs for Intuit API responses
  SyncCoordinator.swift          — Queue orchestration, connectivity monitoring
  QB_INTEGRATION.md              — Integration design doc

Services/
  PDFGenerator.swift             — HTML→PDF for proposals and invoices (Pro: no watermark)
  SubscriptionManager.swift      — StoreKit 2 subscription state, purchase, restore
  ProTierService.swift           — Free tier limit enforcement via SwiftData counts
  WidgetDataService.swift        — Widget data types, protocols, App Group helpers

SeedData/
  MarineTemplates.swift          — 9 marine-specific templates with real FL pricing
  SeedTemplates.swift            — Additional templates

MMCCWidgets/     — WidgetKit extension
  MMCCProposalsWidget.swift      — Open proposals + unpaid totals widget
  MMCCStatsWidget.swift          — Stats widget variant
  MMCCWidgetBundle.swift         — Widget bundle entry
  WidgetDataReader.swift         — App Group reader
```

## Build Order Progress

### Week 1: Speed Core — DONE
1. [x] Xcode project + SwiftData models + ModelContainer
2. [x] BusinessProfile onboarding
3. [x] JobTemplate model + marine seed templates
4. [x] Estimate creation from template
5. [x] SavedItem library with CRUD (LibraryView + SavedItemEditorSheet)
6. [x] Freeform estimate path + customer inline creation (blank estimate + CustomerPickerSheet)
7. [x] PDF generation

### Week 2: Invoice Pipeline + QB — DONE
8. [x] Estimate → Invoice conversion + status tracking
9. [x] Payment recording
10. [x] Send via Share Sheet (PDF sharing)
11. [x] Dashboard
12. [x] QB OAuth flow (QBAuthManager — iOS layer complete, Cloudflare Worker deferred)
13. [x] QB sync (QBSyncService + SyncCoordinator — iOS layer complete, needs Worker + Intuit credentials)

### Week 3: Monetization — DONE
14. [x] StoreKit 2 subscriptions (SubscriptionManager, PaywallView, purchase + restore)
15. [x] Free tier limit enforcement (ProTierService, calendar-month reset)
16. [x] Pro gates (QB sync, PDF watermark, CSV export)
17. [x] Dock Accessories template (9th marine template)

### Week 4: Polish & Features — DONE
18. [x] WidgetKit extension (proposals, stats, lock screen)
19. [x] Send to Customer (email/iMessage with pre-filled PDF) — SendToCustomerSheet
20. [x] Global Search across proposals, invoices, customers, saved items — GlobalSearchView
21. [x] Dashboard revenue charts (6-month bar chart + win rate ring) — RevenueChartView
22. [x] Estimate→Proposal rename (ProposalMigration.swift)
23. [x] Save As Template from proposal detail

### Up Next
- [ ] Cloudflare Worker deployment (token exchange + refresh)
- [ ] Intuit Developer app setup + sandbox testing
- [ ] Google Drive integration (wire file upload/download or cut the UI)
- [ ] Photo attachments on proposals
- [ ] CSV export implementation
- [ ] iPad NavigationSplitView optimization
- [ ] TestFlight beta with local Cape Coral contractors

## Claude Code Automations

### Skills
- `/build` — Regenerate Xcode project (XcodeGen) and build. Use after any model or project.yml change.
- `marine-context` — (Claude-only, auto-loaded) Marine construction domain knowledge.

### Agents
- `swiftdata-reviewer` — Reviews SwiftData models for CloudKit compatibility.
- `liquid-glass-checker` — Scans views for .glassEffect() violations.

### Hooks (automatic)
- **SwiftFormat on edit** — Every `.swift` file is auto-formatted after Edit/Write.
- **Block entitlements/pbxproj** — Prevents accidental edits. Use `project.yml` for project config changes.

### MCP Servers
- **context7** — Live documentation lookup for SwiftUI, SwiftData, StoreKit, etc.
- **playwright** — Browser automation for visual testing.

## Common Patterns

### CloudKit-safe relationship append
```swift
if estimate.sections == nil { estimate.sections = [] }
estimate.sections?.append(section)
```

### CloudKit-safe relationship iteration
```swift
for section in (estimate.sections ?? []).sorted(by: { $0.sortOrder < $1.sortOrder }) { ... }
```

### Status color in ternary (explicit Color prefix)
```swift
.foregroundStyle(invoice.isOverdue ? Color.statusOverdue : Color.white.opacity(0.5))
```

### #Predicate with external values (CRITICAL)
`#Predicate` cannot capture properties from non-local objects. Extract to a local `let` first:
```swift
// WRONG — compiler error
let descriptor = FetchDescriptor<Estimate>(predicate: #Predicate { $0.id == item.entityID })

// RIGHT — capture into local let
let entityID = item.entityID
let descriptor = FetchDescriptor<Estimate>(predicate: #Predicate { $0.id == entityID })
```

### Codable structs with `Type` property
Swift won't allow a stored property named `Type` (conflicts with metatype). Use CodingKeys:
```swift
let ItemType: String?
enum CodingKeys: String, CodingKey {
    case ItemType = "Type"
}
```

### UIKit delegate wrappers (Swift 6 strict concurrency)
When wrapping UIKit delegates in `UIViewControllerRepresentable`, use `@preconcurrency` on the protocol conformance and `@MainActor` on delegate methods:
```swift
final class Coordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
    @MainActor
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        // safe to update @Binding here
    }
}
```

### Optional @Environment for QB services
QB services may be nil before initialization. Use optional environment:
```swift
@Environment(SyncCoordinator.self) private var syncCoordinator: SyncCoordinator?
// Then guard: if let coordinator = syncCoordinator { ... }
```

### project.yml — XcodeGen gotchas
- `info:` block REQUIRES `path:` (e.g. `path: MMCC/Info.plist`) — XcodeGen generates the plist there
- Exclude stale `.xcodeproj` dirs from sources: `"PocketBid.xcodeproj/**"`, `"MMCC.xcodeproj/**"`
- `DEVELOPMENT_TEAM: A6H72TGWNL` — required for device builds, not just simulator
- Widget data types live in `Services/WidgetDataService.swift` — do NOT duplicate in MMCCApp.swift
