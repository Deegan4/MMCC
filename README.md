# MMCC

## What This Is
The fastest estimate app for boat dock builders and marine contractors. 60-second bids for docks, seawalls, pilings, boat lifts, and marine construction. Connects to QuickBooks Online. No one else builds for this niche.

**One-liner:** 60-second estimates for dock builders. Syncs to QuickBooks.

## The Niche
Boat dock builders, seawall contractors, marine construction companies. These contractors build:
- **Boat docks** (wood, composite, aluminum — $15-60/sqft)
- **Seawalls/bulkheads** (vinyl, concrete, steel, riprap — $150-1,200/linear ft)
- **Boat lifts** (manual, electric, hydraulic — $2K-20K)
- **Pilings** (wood, concrete, steel — driven, jetted, drilled)
- **Boathouses** (covered docks, $10K-50K+)
- **Rip rap / rock revetment** ($70-400/linear ft)
- **Dock repair / seawall repair**
- **Dredging** (residential and commercial)

They currently use QuickBooks (which breaks on mobile), paper estimates, or generic contractor apps that don't understand marine construction pricing, materials, or permit requirements.

## Why This Wins
1. **Zero competition** — No iOS app targets marine/dock contractors specifically
2. **Niche pricing knowledge** — Seed templates with real marine construction pricing (pilings per LF, seawall per LF, decking per sqft)
3. **Cape Coral, FL base** — Developer lives in one of the densest marine contractor markets in the US
4. **QB sync** — Dock builders already use QuickBooks for accounting. MMCC plugs into their existing books.

## Tech Stack
- **iOS 26+**, SwiftUI, Liquid Glass
- **SwiftData** (offline-first, auto-save)
- **CloudKit** (cross-device sync, free)
- **PDFKit** (local PDF generation <1 sec)
- **StoreKit 2** (subscriptions)
- **QuickBooks Online REST API** (OAuth 2.0)
- **Cloudflare Worker** (OAuth token relay, free tier)

## The 6 QuickBooks Pain Points MMCC Fixes

| # | QB Problem | MMCC Fix |
|---|---|---|
| 1 | Estimates crash, lose hours of work | SwiftData auto-saves every keystroke. Offline-first. |
| 2 | Forced UI redesigns break workflows | Stable interface. Contractor controls sort/fields. |
| 3 | Cost-plus invoices are flat grocery receipts | Grouped sections: Pilings, Decking, Electrical, Lifts, Permits. |
| 4 | Mobile app is a shell of desktop | Full-power: job site address, water depth, custom fields, templates. |
| 5 | Relentless price increases | $9.99/mo for everything QB mobile can't do. |
| 6 | Customer support is adversarial | Direct dev support from someone who knows marine work. |

## Project Structure

```
MMCC/
├── Models/               # SwiftData @Model classes
│   ├── BusinessProfile.swift
│   ├── Customer.swift
│   ├── Estimate.swift      # + EstimateSection + EstimateLineItem
│   ├── Invoice.swift       # + InvoiceSection + InvoiceLineItem + Payment
│   ├── JobTemplate.swift   # + TemplateSection + TemplateItem
│   └── SavedItem.swift     # + SyncQueueItem
├── Enums/
│   └── AppEnums.swift
├── Services/
│   ├── PDFGenerator.swift
│   ├── EstimateService.swift
│   └── SyncCoordinator.swift
├── QuickBooks/
│   ├── QBAuthManager.swift
│   ├── QBSyncService.swift
│   └── QB_INTEGRATION.md
├── Views/
│   ├── ContentView.swift
│   ├── Onboarding/
│   ├── Dashboard/
│   ├── Estimates/
│   ├── Invoices/
│   ├── Library/
│   ├── Settings/
│   └── Components/
├── SeedData/
│   └── MarineTemplates.swift    # Dock, seawall, lift, piling templates with real pricing
├── ARCHITECTURE.md
├── CLAUDE_CODE.md
└── README.md
```

## Monetization

| Feature | Free | Pro ($9.99/mo or $79.99/yr) |
|---|---|---|
| Estimates/month | 5 | Unlimited |
| Invoices/month | 3 | Unlimited |
| Job Templates | 3 | Unlimited |
| Saved Items | 20 | Unlimited |
| Customers | 10 | Unlimited |
| Your logo on PDF | No | Yes |
| Connect to QuickBooks | No | Yes |
| Milestone splits | No | Yes |
| CSV export | No | Yes |
| Custom fields | 2 | Unlimited |

## Liquid Glass Design
- `.glassEffect()` on: tab bar, toolbars, sheets, CTAs, dashboard cards, sync badge
- NO glass on: content (forms, lists, invoices), PDF output, text inputs
- Test in: Light, Dark, Tinted, Clear, Increased Contrast modes
- Multi-layer icon via Icon Composer (Xcode 26)
- A13+ minimum (iOS 26)

## App Store Metadata
- **Title:** MMCC: Dock Builder Estimates
- **Subtitle:** Marine Contractor Bids + QuickBooks
- **Keywords:** dock builder estimate, marine contractor, seawall, boat lift, piling, dock construction, marine estimate, boat dock bid, QuickBooks sync
- **Primary Category:** Business
- **Secondary:** Productivity
