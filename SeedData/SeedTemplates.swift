import Foundation

/// Marine construction job templates with real SW Florida pricing (2025-2026).
/// Contractor customizes to their market on first use.
///
/// Pricing sources: HomeGuide, The Hull Truth forums, Cape Coral contractor listings,
/// industry averages for Lee/Charlotte/Collier County FL.
enum SeedTemplates {
    
    // MARK: - Template Definition Type
    
    struct TemplateDef {
        let name: String
        let sections: [SectionDef]
        let defaultNotes: String
        let defaultTerms: String
    }
    
    struct SectionDef {
        let name: String
        let items: [ItemDef]
    }
    
    struct ItemDef {
        let description: String
        let qty: Decimal
        let price: Decimal
        let unit: String // UnitType.abbreviation
    }
    
    // MARK: - All Templates
    
    static let all: [TemplateDef] = [
        newDockWood,
        newDockComposite,
        seawallReplacementConcrete,
        seawallReplacementVinyl,
        boatLiftInstall16K,
        boatLiftInstall10K,
        dockRepairPilingReplacement,
        seawallCapRepair,
        floatingDock,
        marineElectrical,
    ]
    
    // ──────────────────────────────────────────
    // 1. New Dock — Pressure Treated Wood
    // ──────────────────────────────────────────
    static let newDockWood = TemplateDef(
        name: "New Dock — Pressure Treated Wood",
        sections: [
            SectionDef(name: "Pilings / Foundation", items: [
                ItemDef(description: "Pressure treated wood pilings, 8\" diameter, driven", qty: 8, price: 650, unit: "ea"),
                ItemDef(description: "Piling caps — stainless steel", qty: 8, price: 35, unit: "ea"),
            ]),
            SectionDef(name: "Decking / Framing", items: [
                ItemDef(description: "Pressure treated 2x8 stringers", qty: 120, price: 8, unit: "LF"),
                ItemDef(description: "Pressure treated 5/4x6 decking", qty: 400, price: 6, unit: "SF"),
                ItemDef(description: "Stainless steel hardware package", qty: 1, price: 450, unit: "LS"),
                ItemDef(description: "Dock cleats — 10\" aluminum", qty: 4, price: 65, unit: "ea"),
                ItemDef(description: "Rub rail — vinyl", qty: 60, price: 12, unit: "LF"),
            ]),
            SectionDef(name: "Electrical / Lighting", items: [
                ItemDef(description: "LED dock post lights", qty: 4, price: 125, unit: "ea"),
                ItemDef(description: "Electrical run — conduit, wire, connections", qty: 1, price: 850, unit: "LS"),
                ItemDef(description: "GFI outlet — weatherproof", qty: 2, price: 175, unit: "ea"),
            ]),
            SectionDef(name: "Permits / Engineering", items: [
                ItemDef(description: "Lee County dock permit", qty: 1, price: 500, unit: "ea"),
                ItemDef(description: "Marine survey / engineering", qty: 1, price: 750, unit: "ea"),
            ]),
            SectionDef(name: "Mobilization / Barge", items: [
                ItemDef(description: "Barge mobilization and demobilization", qty: 1, price: 1500, unit: "LS"),
            ]),
        ],
        defaultNotes: "Scope: Remove existing dock (if applicable). Drive new pilings. Build new pressure treated wood dock per approved plans. Includes electrical as specified. Excludes seawall work, boat lift, and landscaping.\n\nTimeline: Approximately 2-3 weeks from permit approval.\n\nAll work performed per Lee County and FDEP requirements.",
        defaultTerms: "Payment: 1/3 at contract signing, 1/3 at piling completion, 1/3 at final completion. Proposal valid for 30 days. Changes to scope will be documented as change orders. Contractor carries marine contractor insurance and general liability."
    )
    
    // ──────────────────────────────────────────
    // 2. New Dock — Composite (Trex/similar)
    // ──────────────────────────────────────────
    static let newDockComposite = TemplateDef(
        name: "New Dock — Composite Decking",
        sections: [
            SectionDef(name: "Pilings / Foundation", items: [
                ItemDef(description: "Pressure treated wood pilings, 8\" diameter, driven", qty: 8, price: 650, unit: "ea"),
                ItemDef(description: "Piling caps — stainless steel", qty: 8, price: 35, unit: "ea"),
            ]),
            SectionDef(name: "Decking / Framing", items: [
                ItemDef(description: "Pressure treated 2x8 stringers", qty: 120, price: 8, unit: "LF"),
                ItemDef(description: "Composite decking (Trex or equivalent)", qty: 400, price: 14, unit: "SF"),
                ItemDef(description: "Hidden fastener system", qty: 400, price: 2, unit: "SF"),
                ItemDef(description: "Composite fascia board", qty: 60, price: 18, unit: "LF"),
                ItemDef(description: "Dock cleats — 10\" aluminum", qty: 4, price: 65, unit: "ea"),
                ItemDef(description: "Rub rail — vinyl", qty: 60, price: 12, unit: "LF"),
            ]),
            SectionDef(name: "Electrical / Lighting", items: [
                ItemDef(description: "LED dock post lights", qty: 4, price: 125, unit: "ea"),
                ItemDef(description: "Electrical run — conduit, wire, connections", qty: 1, price: 850, unit: "LS"),
                ItemDef(description: "GFI outlet — weatherproof", qty: 2, price: 175, unit: "ea"),
            ]),
            SectionDef(name: "Permits / Engineering", items: [
                ItemDef(description: "Lee County dock permit", qty: 1, price: 500, unit: "ea"),
                ItemDef(description: "Marine survey / engineering", qty: 1, price: 750, unit: "ea"),
            ]),
            SectionDef(name: "Mobilization / Barge", items: [
                ItemDef(description: "Barge mobilization and demobilization", qty: 1, price: 1500, unit: "LS"),
            ]),
        ],
        defaultNotes: "Scope: Remove existing dock (if applicable). Drive new pilings. Build new dock with composite decking per approved plans. Includes electrical as specified. Excludes seawall work, boat lift, and landscaping.\n\nComposite decking carries manufacturer's 25-year warranty.\n\nTimeline: Approximately 2-3 weeks from permit approval.",
        defaultTerms: "Payment: 1/3 at contract signing, 1/3 at piling completion, 1/3 at final completion. Proposal valid for 30 days."
    )
    
    // ──────────────────────────────────────────
    // 3. Seawall Replacement — Concrete
    // ──────────────────────────────────────────
    static let seawallReplacementConcrete = TemplateDef(
        name: "Seawall Replacement — Poured Concrete",
        sections: [
            SectionDef(name: "Demolition", items: [
                ItemDef(description: "Remove existing seawall", qty: 80, price: 45, unit: "LF"),
                ItemDef(description: "Debris removal and disposal", qty: 1, price: 2500, unit: "LS"),
            ]),
            SectionDef(name: "Seawall / Bulkhead", items: [
                ItemDef(description: "Poured concrete seawall — 6' height", qty: 80, price: 350, unit: "LF"),
                ItemDef(description: "Steel rebar reinforcement", qty: 80, price: 25, unit: "LF"),
                ItemDef(description: "Tiebacks / deadman anchors", qty: 10, price: 280, unit: "ea"),
                ItemDef(description: "Concrete cap — 12\" wide", qty: 80, price: 35, unit: "LF"),
                ItemDef(description: "Weep holes — PVC", qty: 16, price: 25, unit: "ea"),
            ]),
            SectionDef(name: "Backfill", items: [
                ItemDef(description: "Clean fill / backfill material", qty: 60, price: 18, unit: "CY"),
                ItemDef(description: "Compaction and grading", qty: 1, price: 1200, unit: "LS"),
            ]),
            SectionDef(name: "Permits / Engineering", items: [
                ItemDef(description: "Lee County seawall permit", qty: 1, price: 750, unit: "ea"),
                ItemDef(description: "FDEP permit (if applicable)", qty: 1, price: 500, unit: "ea"),
                ItemDef(description: "Engineering / structural plans", qty: 1, price: 2500, unit: "ea"),
            ]),
            SectionDef(name: "Mobilization / Barge", items: [
                ItemDef(description: "Barge and equipment mobilization", qty: 1, price: 3500, unit: "LS"),
                ItemDef(description: "Turbidity barrier", qty: 1, price: 800, unit: "LS"),
            ]),
        ],
        defaultNotes: "Scope: Complete removal of existing seawall and replacement with new poured concrete seawall. Includes backfill, grading, and cap. Excludes dock work, landscaping, and irrigation repair.\n\nSeawall height: 6' (adjustable based on survey). Length: approximately 80 LF (verify with survey).\n\nTimeline: 4-6 weeks from permit approval.\n\nAll work meets or exceeds Lee County and FDEP requirements.",
        defaultTerms: "Payment: 1/3 at contract signing, 1/3 at wall pour, 1/3 at final completion and backfill. Proposal valid for 30 days. Material prices subject to change if not accepted within 30 days."
    )
    
    // ──────────────────────────────────────────
    // 4. Seawall Replacement — Vinyl Sheet Pile
    // ──────────────────────────────────────────
    static let seawallReplacementVinyl = TemplateDef(
        name: "Seawall Replacement — Vinyl Sheet Pile",
        sections: [
            SectionDef(name: "Demolition", items: [
                ItemDef(description: "Remove existing seawall", qty: 80, price: 40, unit: "LF"),
                ItemDef(description: "Debris removal and disposal", qty: 1, price: 2000, unit: "LS"),
            ]),
            SectionDef(name: "Seawall / Bulkhead", items: [
                ItemDef(description: "Vinyl sheet pile — driven", qty: 80, price: 275, unit: "LF"),
                ItemDef(description: "Concrete cap — poured", qty: 80, price: 45, unit: "LF"),
                ItemDef(description: "Tiebacks / deadman anchors", qty: 10, price: 280, unit: "ea"),
                ItemDef(description: "Return walls (if needed)", qty: 2, price: 850, unit: "ea"),
            ]),
            SectionDef(name: "Backfill", items: [
                ItemDef(description: "Clean fill material", qty: 50, price: 18, unit: "CY"),
                ItemDef(description: "Compaction and grading", qty: 1, price: 1000, unit: "LS"),
            ]),
            SectionDef(name: "Permits / Engineering", items: [
                ItemDef(description: "County seawall permit", qty: 1, price: 750, unit: "ea"),
                ItemDef(description: "Engineering plans", qty: 1, price: 2000, unit: "ea"),
            ]),
            SectionDef(name: "Mobilization / Barge", items: [
                ItemDef(description: "Equipment mobilization", qty: 1, price: 3000, unit: "LS"),
                ItemDef(description: "Turbidity barrier", qty: 1, price: 800, unit: "LS"),
            ]),
        ],
        defaultNotes: "Scope: Remove existing seawall. Install new vinyl sheet pile seawall with concrete cap. Includes backfill. Excludes dock, landscaping, irrigation.\n\nVinyl sheet pile carries 50+ year expected lifespan.\n\nTimeline: 3-5 weeks from permit approval.",
        defaultTerms: "Payment: 1/3 at signing, 1/3 at sheet pile completion, 1/3 at cap and backfill. Proposal valid for 30 days."
    )
    
    // ──────────────────────────────────────────
    // 5. Boat Lift Install — 16,000 lb
    // ──────────────────────────────────────────
    static let boatLiftInstall16K = TemplateDef(
        name: "Boat Lift Installation — 16,000 lb",
        sections: [
            SectionDef(name: "Boat Lift", items: [
                ItemDef(description: "16,000 lb capacity boat lift — aluminum", qty: 1, price: 12500, unit: "ea"),
                ItemDef(description: "Boat lift motor — 12V DC", qty: 1, price: 1800, unit: "ea"),
                ItemDef(description: "Bunks / cradle — custom fit", qty: 1, price: 650, unit: "ea"),
                ItemDef(description: "Remote control", qty: 1, price: 350, unit: "ea"),
            ]),
            SectionDef(name: "Pilings / Foundation", items: [
                ItemDef(description: "Lift pilings — 10\" pressure treated, driven", qty: 4, price: 750, unit: "ea"),
            ]),
            SectionDef(name: "Electrical / Lighting", items: [
                ItemDef(description: "Lift electrical — dedicated circuit, GFI, wiring", qty: 1, price: 950, unit: "LS"),
            ]),
            SectionDef(name: "Permits / Engineering", items: [
                ItemDef(description: "Lift permit", qty: 1, price: 350, unit: "ea"),
            ]),
            SectionDef(name: "Mobilization / Barge", items: [
                ItemDef(description: "Delivery and installation", qty: 1, price: 1200, unit: "LS"),
            ]),
        ],
        defaultNotes: "Scope: Supply and install 16,000 lb aluminum boat lift with 4 new pilings, motor, bunks, remote, and electrical. Customer to verify boat specs for cradle sizing.\n\nTimeline: 1-2 weeks from permit approval.",
        defaultTerms: "Payment: 50% deposit at contract signing, 50% at completion. Proposal valid for 30 days. Lift carries manufacturer warranty."
    )
    
    // ──────────────────────────────────────────
    // 6. Boat Lift Install — 10,000 lb
    // ──────────────────────────────────────────
    static let boatLiftInstall10K = TemplateDef(
        name: "Boat Lift Installation — 10,000 lb",
        sections: [
            SectionDef(name: "Boat Lift", items: [
                ItemDef(description: "10,000 lb capacity boat lift — aluminum", qty: 1, price: 7500, unit: "ea"),
                ItemDef(description: "Boat lift motor — 12V DC", qty: 1, price: 1500, unit: "ea"),
                ItemDef(description: "Bunks / cradle", qty: 1, price: 450, unit: "ea"),
                ItemDef(description: "Remote control", qty: 1, price: 350, unit: "ea"),
            ]),
            SectionDef(name: "Pilings / Foundation", items: [
                ItemDef(description: "Lift pilings — 8\" pressure treated, driven", qty: 4, price: 650, unit: "ea"),
            ]),
            SectionDef(name: "Electrical / Lighting", items: [
                ItemDef(description: "Lift electrical — dedicated circuit, GFI, wiring", qty: 1, price: 850, unit: "LS"),
            ]),
            SectionDef(name: "Permits / Engineering", items: [
                ItemDef(description: "Lift permit", qty: 1, price: 350, unit: "ea"),
            ]),
            SectionDef(name: "Mobilization / Barge", items: [
                ItemDef(description: "Delivery and installation", qty: 1, price: 1000, unit: "LS"),
            ]),
        ],
        defaultNotes: "Scope: Supply and install 10,000 lb aluminum boat lift with 4 new pilings, motor, bunks, remote, and electrical.\n\nTimeline: 1-2 weeks from permit approval.",
        defaultTerms: "Payment: 50% deposit, 50% at completion. Proposal valid for 30 days."
    )
    
    // ──────────────────────────────────────────
    // 7. Dock Repair — Piling Replacement
    // ──────────────────────────────────────────
    static let dockRepairPilingReplacement = TemplateDef(
        name: "Dock Repair — Piling Replacement",
        sections: [
            SectionDef(name: "Pilings / Foundation", items: [
                ItemDef(description: "Remove deteriorated piling", qty: 4, price: 350, unit: "ea"),
                ItemDef(description: "New pressure treated piling — 8\" diameter, driven", qty: 4, price: 650, unit: "ea"),
                ItemDef(description: "Piling caps — stainless", qty: 4, price: 35, unit: "ea"),
            ]),
            SectionDef(name: "Decking / Framing", items: [
                ItemDef(description: "Re-attach / sister stringers at new pilings", qty: 4, price: 225, unit: "ea"),
                ItemDef(description: "Replace damaged decking boards", qty: 20, price: 12, unit: "SF"),
            ]),
            SectionDef(name: "Mobilization / Barge", items: [
                ItemDef(description: "Barge mobilization", qty: 1, price: 1200, unit: "LS"),
            ]),
        ],
        defaultNotes: "Scope: Replace 4 deteriorated pilings. Re-attach existing dock framing to new pilings. Replace damaged decking in piling areas. Excludes full deck replacement, seawall work, and electrical.\n\nPiling count and condition to be verified on-site.",
        defaultTerms: "Payment: 50% deposit, 50% at completion. Proposal valid for 30 days."
    )
    
    // ──────────────────────────────────────────
    // 8. Seawall Cap Repair
    // ──────────────────────────────────────────
    static let seawallCapRepair = TemplateDef(
        name: "Seawall Cap Repair",
        sections: [
            SectionDef(name: "Seawall / Bulkhead", items: [
                ItemDef(description: "Remove damaged concrete cap", qty: 40, price: 25, unit: "LF"),
                ItemDef(description: "Pour new concrete cap — 12\" wide", qty: 40, price: 55, unit: "LF"),
                ItemDef(description: "Rebar reinforcement", qty: 40, price: 12, unit: "LF"),
                ItemDef(description: "Epoxy crack injection (if applicable)", qty: 10, price: 45, unit: "LF"),
            ]),
            SectionDef(name: "Mobilization / Barge", items: [
                ItemDef(description: "Equipment mobilization (land-side)", qty: 1, price: 500, unit: "LS"),
            ]),
        ],
        defaultNotes: "Scope: Remove and replace damaged seawall cap. Patch/epoxy existing wall cracks as needed. Excludes full seawall replacement, backfill, and dock work.\n\nActual linear footage to be confirmed on-site.",
        defaultTerms: "Payment: 50% deposit, 50% at completion. Proposal valid for 30 days."
    )
    
    // ──────────────────────────────────────────
    // 9. Floating Dock Installation
    // ──────────────────────────────────────────
    static let floatingDock = TemplateDef(
        name: "Floating Dock Installation",
        sections: [
            SectionDef(name: "Pilings / Foundation", items: [
                ItemDef(description: "Guide pilings — 8\" pressure treated", qty: 4, price: 600, unit: "ea"),
                ItemDef(description: "Piling sleeves / guides — HDPE", qty: 4, price: 120, unit: "ea"),
            ]),
            SectionDef(name: "Decking / Framing", items: [
                ItemDef(description: "Floating dock section — 8' x 20' modular", qty: 2, price: 3500, unit: "ea"),
                ItemDef(description: "Dock-to-shore gangway — 16' aluminum", qty: 1, price: 2800, unit: "ea"),
                ItemDef(description: "Dock cleats — aluminum", qty: 4, price: 55, unit: "ea"),
                ItemDef(description: "Bumpers / rub rail", qty: 8, price: 35, unit: "ea"),
            ]),
            SectionDef(name: "Permits / Engineering", items: [
                ItemDef(description: "Dock permit", qty: 1, price: 500, unit: "ea"),
            ]),
            SectionDef(name: "Mobilization / Barge", items: [
                ItemDef(description: "Delivery and installation", qty: 1, price: 1500, unit: "LS"),
            ]),
        ],
        defaultNotes: "Scope: Install floating dock system with guide pilings and gangway. Dock sections are modular composite construction. Excludes seawall, boat lift, and electrical.\n\nFloating docks are ideal for areas with significant tidal change or fluctuating water levels.",
        defaultTerms: "Payment: 50% deposit, 50% at completion. Proposal valid for 30 days."
    )
    
    // ──────────────────────────────────────────
    // 10. Marine Electrical — Shore Power
    // ──────────────────────────────────────────
    static let marineElectrical = TemplateDef(
        name: "Marine Electrical — Shore Power + Lighting",
        sections: [
            SectionDef(name: "Electrical / Lighting", items: [
                ItemDef(description: "Shore power pedestal — 30A/50A combo", qty: 1, price: 1200, unit: "ea"),
                ItemDef(description: "Electrical run — panel to dock (UF cable in conduit)", qty: 1, price: 1800, unit: "LS"),
                ItemDef(description: "Sub-panel at dock — 100A", qty: 1, price: 650, unit: "ea"),
                ItemDef(description: "GFI breakers", qty: 4, price: 85, unit: "ea"),
                ItemDef(description: "Weatherproof outlets", qty: 4, price: 145, unit: "ea"),
                ItemDef(description: "LED dock lights — post mount", qty: 6, price: 125, unit: "ea"),
                ItemDef(description: "LED underwater lights", qty: 2, price: 350, unit: "ea"),
                ItemDef(description: "Photocell / timer for lighting", qty: 1, price: 85, unit: "ea"),
            ]),
            SectionDef(name: "Permits / Engineering", items: [
                ItemDef(description: "Electrical permit", qty: 1, price: 250, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Install shore power pedestal, dock sub-panel, outlets, and lighting as specified. Includes all wiring from main panel to dock. Excludes dock construction, seawall, and boat lift electrical.\n\nAll work per NEC and local code requirements. GFCI protection on all dock circuits.",
        defaultTerms: "Payment: 50% deposit, 50% at completion and inspection. Proposal valid for 30 days."
    )
}
