# Architecture Decisions

## ADR-001: iOS 26+ Only, Liquid Glass
No backward compat. A13+ min. Full Liquid Glass via .glassEffect().

## ADR-002: SwiftData, No Core Data
@Model macro. Auto-save on mutation = no save buttons.

## ADR-003: No Backend for Core
CloudKit (free) for sync. PDFKit (local) for PDF. Only server: Cloudflare Worker for QB OAuth.

## ADR-004: QB Push-on-Action
Sync when contractor sends estimate or records payment. Queue if offline.

## ADR-005: QB Sync is Pro-Only
Conversion trigger. Free tier works standalone.

## ADR-006: Offline Queue
SyncQueueItem model. FIFO. Max 3 retries. HVAC contractors work on job sites with no signal.

## ADR-007: Local PDF via PDFKit
Sub-second. Offline. No customer data leaves device.

## ADR-008: CloudKit Single Container
One ModelContainer. Last-write-wins conflicts acceptable.

## ADR-009: Auto-Increment Numbers
P-001, INV-001. QB number stored separately.

## ADR-010: Section-Based Structure
HVAC sections: Equipment, Ductwork, Refrigerant, Electrical, Controls, Insulation, Labor, Permits.

## ADR-011: HVAC Niche
Every default, template, unit is HVAC-specific.

## ADR-012: Property & System Metadata
System type, service type, property type. Domain-specific metadata no generic app captures.
