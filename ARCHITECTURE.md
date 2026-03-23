# Architecture Decisions

## ADR-001: iOS 26+ Only, Liquid Glass
No backward compat. A13+ min. Full Liquid Glass via .glassEffect().

## ADR-002: SwiftData, No Core Data
@Model macro. Auto-save on mutation = no save buttons = Pain Point #1 solved.

## ADR-003: No Backend for Core
CloudKit (free) for sync. PDFKit (local) for PDF. Only server: Cloudflare Worker for QB OAuth.

## ADR-004: QB Push-on-Action
Sync when contractor sends estimate or records payment. Queue if offline.

## ADR-005: QB Sync is Pro-Only
Conversion trigger. Free tier works standalone.

## ADR-006: Offline Queue
SyncQueueItem model. FIFO. Max 3 retries. Marine contractors work on water with no signal.

## ADR-007: Local PDF via PDFKit
Sub-second. Offline. No customer data leaves device.

## ADR-008: CloudKit Single Container
One ModelContainer. Last-write-wins conflicts acceptable.

## ADR-009: Auto-Increment Numbers
EST-001, INV-001. QB number stored separately.

## ADR-010: Section-Based Structure
Marine sections: Pilings, Decking, Seawall, Boat Lift, Electrical, Permits, Mobilization.

## ADR-011: Marine Niche Only
NOT generic. Every default, template, unit is marine construction specific.

## ADR-012: Waterfront Property Metadata
Waterway name, type, depth, tidal, seawall type, permit jurisdiction. No generic app has this.
