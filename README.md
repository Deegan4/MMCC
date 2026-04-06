# MMCC

## What This Is
The fastest estimate and invoice app for HVAC contractors. 60-second bids for AC replacements, furnace installs, ductwork, mini-splits, heat pumps, and more. Connects to QuickBooks Online.

**One-liner:** 60-second estimates for HVAC contractors. Syncs to QuickBooks.

## The Niche
HVAC contractors, heating and cooling companies, and mechanical contractors. These contractors do:
- **AC Replacement** (split systems, package units — $3K-$15K)
- **Furnace Installation** (gas, electric, heat pump — $2K-$8K)
- **Ductwork** (new construction, replacement, repair — $2K-$12K)
- **Mini-Split Systems** (single and multi-zone — $2K-$10K)
- **Heat Pump Conversions** ($5K-$15K)
- **Commercial RTU** (rooftop unit replacement — $5K-$25K+)
- **Maintenance Agreements** ($150-$500/year)
- **Refrigerant Recharge & Repair**

## Why This Wins
1. **HVAC-specific templates** — Seed templates with real HVAC pricing (equipment, ductwork, refrigerant, electrical, permits)
2. **Section-based estimates** — Equipment, Ductwork, Electrical, Labor, Permits — not generic line items
3. **QB sync** — HVAC contractors already use QuickBooks. MMCC plugs into their existing books.
4. **Offline-first** — Works on job sites with no signal

## Tech Stack
- **iOS 26+**, SwiftUI, Liquid Glass
- **SwiftData** (offline-first, auto-save)
- **CloudKit** (cross-device sync, free)
- **PDFKit** (local PDF generation <1 sec)
- **StoreKit 2** (subscriptions)
- **QuickBooks Online REST API** (OAuth 2.0)
- **Cloudflare Worker** (OAuth token relay, free tier)

## Project Structure

```
MMCC/
├── Models/               # SwiftData @Model classes
│   ├── BusinessProfile.swift
│   ├── Customer.swift
│   ├── Proposal.swift    # + ProposalSection + ProposalLineItem
│   ├── Invoice.swift     # + InvoiceSection + InvoiceLineItem + Payment
│   ├── JobTemplate.swift # + TemplateSection + TemplateItem
│   └── SavedItem.swift   # + SyncQueueItem
├── Enums/
│   └── AppEnums.swift
├── Services/
│   ├── PDFGenerator.swift
│   ├── SubscriptionManager.swift
│   └── ProTierService.swift
├── QuickBooks/
│   ├── QBAuthManager.swift
│   ├── QBSyncService.swift
│   └── SyncCoordinator.swift
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
│   ├── MarineTemplates.swift  # HVAC job templates with real pricing
│   └── SeedTemplates.swift
├── ARCHITECTURE.md
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

## App Store Metadata
- **Title:** MMCC: HVAC Estimates & Invoices
- **Subtitle:** HVAC Contractor Bids + QuickBooks
- **Keywords:** HVAC estimate, heating cooling contractor, AC replacement, furnace install, ductwork, heat pump, mini split, HVAC invoice, QuickBooks sync
- **Primary Category:** Business
- **Secondary:** Productivity
