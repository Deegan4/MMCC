import Foundation

/// Marine construction seed templates with real Florida residential pricing (2025-2026).
/// Contractor customizes to their market on first use.
enum MarineTemplates {
    
    // MARK: - Template Data Structure
    
    struct SeedTemplate {
        let name: String
        let sections: [SeedSection]
        let defaultNotes: String
        let defaultTerms: String
    }
    
    struct SeedSection {
        let name: String
        let items: [SeedItem]
    }
    
    struct SeedItem {
        let description: String
        let qty: Decimal
        let price: Decimal
        let unit: String // ea, lf, sqft, hr, ls (lump sum)
    }
    
    // MARK: - All Templates
    
    static let all: [SeedTemplate] = [
        residentialDockBuild,
        seawallNewVinyl,
        seawallRepair,
        boatLiftInstall,
        dockRepairRebuild,
        boathouseConstruction,
        ripRapRevetment,
        pilingReplacement,
        dockAccessories,
    ]
    
    // MARK: - 1. Residential Dock Build (Wood/Composite)
    
    static let residentialDockBuild = SeedTemplate(
        name: "Residential Dock Build — 6x40 ft",
        sections: [
            SeedSection(name: "Site Work", items: [
                SeedItem(description: "Old dock demolition and debris removal", qty: 1, price: 2500, unit: "ls"),
                SeedItem(description: "Site preparation and layout", qty: 1, price: 500, unit: "ls"),
            ]),
            SeedSection(name: "Pilings", items: [
                SeedItem(description: "Pressure-treated wood pilings 10\" dia, driven", qty: 8, price: 850, unit: "ea"),
                SeedItem(description: "Piling caps (marine-grade)", qty: 8, price: 25, unit: "ea"),
            ]),
            SeedSection(name: "Framing & Structure", items: [
                SeedItem(description: "Pressure-treated stringers 2x10", qty: 80, price: 8, unit: "lf"),
                SeedItem(description: "Joist hangers and hardware (stainless)", qty: 1, price: 350, unit: "ls"),
                SeedItem(description: "Cross bracing", qty: 1, price: 400, unit: "ls"),
            ]),
            SeedSection(name: "Decking", items: [
                SeedItem(description: "Composite decking (Trex/Azek) — supply and install", qty: 240, price: 18, unit: "sqft"),
                SeedItem(description: "Fascia and trim boards", qty: 1, price: 450, unit: "ls"),
                SeedItem(description: "Hidden fastener system", qty: 240, price: 2.50, unit: "sqft"),
            ]),
            SeedSection(name: "Accessories", items: [
                SeedItem(description: "Dock cleats (stainless steel)", qty: 6, price: 45, unit: "ea"),
                SeedItem(description: "Dock bumpers", qty: 8, price: 35, unit: "ea"),
                SeedItem(description: "Dock ladder (aluminum, fold-up)", qty: 1, price: 350, unit: "ea"),
            ]),
            SeedSection(name: "Electrical", items: [
                SeedItem(description: "Shore power pedestal (30A)", qty: 1, price: 1200, unit: "ea"),
                SeedItem(description: "LED dock lighting (solar)", qty: 6, price: 85, unit: "ea"),
                SeedItem(description: "Electrical conduit and wiring", qty: 1, price: 800, unit: "ls"),
            ]),
            SeedSection(name: "Permits & Engineering", items: [
                SeedItem(description: "County dock permit", qty: 1, price: 750, unit: "ea"),
                SeedItem(description: "DEP/environmental review (if required)", qty: 1, price: 1500, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Demolition of existing dock structure, install new pilings, framing, composite decking, accessories, and electrical. All materials marine-grade. Includes debris removal and disposal. Does not include seawall work, dredging, or boat lift installation. Timeline: approximately 2-3 weeks from permit approval.",
        defaultTerms: "This proposal is valid for 30 days. Payment schedule: 1/3 at contract signing, 1/3 at midpoint (framing complete), 1/3 at completion. All work performed by licensed marine contractor. Permit fees are estimates and may vary by county. Customer responsible for HOA/POA approvals if applicable."
    )
    
    // MARK: - 2. Seawall New Construction (Vinyl)
    
    static let seawallNewVinyl = SeedTemplate(
        name: "Seawall New Construction — Vinyl, 100 LF",
        sections: [
            SeedSection(name: "Site Work", items: [
                SeedItem(description: "Old seawall demolition and removal", qty: 100, price: 75, unit: "lf"),
                SeedItem(description: "Dewatering (if required)", qty: 1, price: 3000, unit: "ls"),
                SeedItem(description: "Site mobilization and barge setup", qty: 1, price: 2500, unit: "ls"),
            ]),
            SeedSection(name: "Seawall", items: [
                SeedItem(description: "Vinyl sheet piling — supply and drive", qty: 100, price: 450, unit: "lf"),
                SeedItem(description: "Concrete cap — poured in place", qty: 100, price: 125, unit: "lf"),
                SeedItem(description: "Deadman anchors / tie-back system", qty: 10, price: 350, unit: "ea"),
                SeedItem(description: "Filter fabric", qty: 100, price: 8, unit: "lf"),
                SeedItem(description: "Backfill — clean fill and compaction", qty: 100, price: 35, unit: "lf"),
                SeedItem(description: "Weep holes / drainage", qty: 10, price: 75, unit: "ea"),
            ]),
            SeedSection(name: "Permits & Engineering", items: [
                SeedItem(description: "Structural engineering plans", qty: 1, price: 3500, unit: "ea"),
                SeedItem(description: "County seawall permit", qty: 1, price: 1500, unit: "ea"),
                SeedItem(description: "DEP environmental permit", qty: 1, price: 2000, unit: "ea"),
                SeedItem(description: "Survey and as-built", qty: 1, price: 1500, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Complete removal of existing seawall and installation of new vinyl sheet pile seawall with concrete cap. Includes all tie-backs, backfill, and drainage. All work performed from water via barge (adjust if land access available). Does not include dock work, landscaping, or irrigation repair. Timeline: approximately 3-4 weeks from permit approval.",
        defaultTerms: "This proposal is valid for 30 days. Payment schedule: 1/3 at contract signing, 1/3 at midpoint (piling driven), 1/3 at completion. Engineering and permit fees are estimates — actual fees billed at cost. Soil conditions may require change orders if rock/coquina encountered. Customer responsible for temporary boat relocation during construction."
    )
    
    // MARK: - 3. Seawall Repair
    
    static let seawallRepair = SeedTemplate(
        name: "Seawall Repair — Cap & Panel",
        sections: [
            SeedSection(name: "Seawall", items: [
                SeedItem(description: "Concrete cap removal and replacement", qty: 25, price: 85, unit: "lf"),
                SeedItem(description: "Panel repair / patching", qty: 5, price: 250, unit: "ea"),
                SeedItem(description: "Crack injection (epoxy)", qty: 10, price: 150, unit: "ea"),
                SeedItem(description: "Tie-back replacement", qty: 3, price: 450, unit: "ea"),
                SeedItem(description: "Backfill — erosion void repair", qty: 1, price: 1200, unit: "ls"),
            ]),
            SeedSection(name: "Site Work", items: [
                SeedItem(description: "Mobilization", qty: 1, price: 800, unit: "ls"),
                SeedItem(description: "Debris removal and cleanup", qty: 1, price: 500, unit: "ls"),
            ]),
            SeedSection(name: "Permits & Engineering", items: [
                SeedItem(description: "Repair permit (if required)", qty: 1, price: 500, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Repair of existing seawall including cap replacement, panel patching, crack injection, and backfill of erosion voids. This is a repair, not a replacement. If structural inspection reveals damage beyond repair scope, a new seawall proposal will be provided. Timeline: 3-5 business days.",
        defaultTerms: "This proposal is valid for 30 days. Payment: 50% at contract signing, 50% at completion. Repair scope may change if hidden damage is discovered — any additional work will be quoted before proceeding."
    )
    
    // MARK: - 4. Boat Lift Install
    
    static let boatLiftInstall = SeedTemplate(
        name: "Boat Lift Install — 10,000 lb Electric",
        sections: [
            SeedSection(name: "Boat Lift", items: [
                SeedItem(description: "10,000 lb capacity boat lift — supply", qty: 1, price: 9500, unit: "ea"),
                SeedItem(description: "Electric motor with remote control", qty: 1, price: 2200, unit: "ea"),
                SeedItem(description: "Bunks / cradle — custom fit", qty: 1, price: 800, unit: "ea"),
                SeedItem(description: "Cable / gear maintenance kit", qty: 1, price: 150, unit: "ea"),
            ]),
            SeedSection(name: "Pilings", items: [
                SeedItem(description: "Lift pilings — pressure-treated 12\" dia, driven", qty: 4, price: 950, unit: "ea"),
            ]),
            SeedSection(name: "Electrical", items: [
                SeedItem(description: "Electrical hookup — lift motor to shore power", qty: 1, price: 1500, unit: "ls"),
                SeedItem(description: "GFI outlet / disconnect at dock", qty: 1, price: 350, unit: "ea"),
            ]),
            SeedSection(name: "Labor", items: [
                SeedItem(description: "Installation labor — lift assembly and mounting", qty: 1, price: 2500, unit: "ls"),
            ]),
            SeedSection(name: "Permits & Engineering", items: [
                SeedItem(description: "Boat lift permit", qty: 1, price: 400, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Supply and install 10,000 lb electric boat lift with 4 new pilings, electrical hookup, and custom bunks. Includes remote control. Customer to confirm boat make/model/weight for proper bunk sizing. Does not include dock modifications. Timeline: 1-2 weeks from permit approval.",
        defaultTerms: "This proposal is valid for 30 days. Payment: 50% deposit at order (lift equipment is special order), 50% at installation complete. Lift warranty per manufacturer terms. Installation warranty: 1 year parts and labor."
    )
    
    // MARK: - 5. Dock Repair / Rebuild
    
    static let dockRepairRebuild = SeedTemplate(
        name: "Dock Repair — Decking & Pilings",
        sections: [
            SeedSection(name: "Site Work", items: [
                SeedItem(description: "Damaged decking removal and disposal", qty: 1, price: 800, unit: "ls"),
            ]),
            SeedSection(name: "Pilings", items: [
                SeedItem(description: "Piling replacement — 10\" dia PT, driven", qty: 3, price: 850, unit: "ea"),
                SeedItem(description: "Piling wrap (fiberglass)", qty: 3, price: 250, unit: "ea"),
            ]),
            SeedSection(name: "Framing & Structure", items: [
                SeedItem(description: "Stringer replacement — PT 2x10", qty: 30, price: 12, unit: "lf"),
                SeedItem(description: "Hardware (stainless bolts, hangers)", qty: 1, price: 250, unit: "ls"),
            ]),
            SeedSection(name: "Decking", items: [
                SeedItem(description: "Composite decking replacement", qty: 120, price: 18, unit: "sqft"),
                SeedItem(description: "Fascia replacement", qty: 1, price: 300, unit: "ls"),
            ]),
            SeedSection(name: "Labor", items: [
                SeedItem(description: "Repair labor", qty: 24, price: 85, unit: "hr"),
            ]),
        ],
        defaultNotes: "Scope: Replace 3 damaged pilings, associated framing, and decking. Existing pilings not being replaced will be inspected and wrapped if needed. Scope may change if additional damage discovered during demolition. Timeline: 3-5 business days.",
        defaultTerms: "This proposal is valid for 30 days. Payment: 50% at start, 50% at completion. Additional damage discovered during work will be documented and quoted before proceeding."
    )
    
    // MARK: - 6. Boathouse Construction
    
    static let boathouseConstruction = SeedTemplate(
        name: "Boathouse — Single Slip, Covered",
        sections: [
            SeedSection(name: "Pilings", items: [
                SeedItem(description: "Structural pilings — 12\" dia PT, driven", qty: 8, price: 1100, unit: "ea"),
            ]),
            SeedSection(name: "Framing & Structure", items: [
                SeedItem(description: "Framing — beams, rafters, trusses", qty: 1, price: 8500, unit: "ls"),
                SeedItem(description: "Stainless steel hardware package", qty: 1, price: 1200, unit: "ls"),
            ]),
            SeedSection(name: "Decking", items: [
                SeedItem(description: "Composite decking — dock area", qty: 300, price: 18, unit: "sqft"),
            ]),
            SeedSection(name: "Boat Lift", items: [
                SeedItem(description: "Boat lift — ceiling mount, 10K lb electric", qty: 1, price: 12000, unit: "ea"),
            ]),
            SeedSection(name: "Electrical", items: [
                SeedItem(description: "Electrical — lift power, lighting, shore power", qty: 1, price: 4500, unit: "ls"),
            ]),
            SeedSection(name: "Accessories", items: [
                SeedItem(description: "Metal roofing — standing seam", qty: 1, price: 6500, unit: "ls"),
                SeedItem(description: "Gutters and downspouts", qty: 1, price: 1200, unit: "ls"),
                SeedItem(description: "Dock cleats, bumpers, ladder", qty: 1, price: 800, unit: "ls"),
            ]),
            SeedSection(name: "Permits & Engineering", items: [
                SeedItem(description: "Engineering plans (structural)", qty: 1, price: 4000, unit: "ea"),
                SeedItem(description: "Building permit + DEP", qty: 1, price: 2500, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Complete single-slip covered boathouse with ceiling-mounted boat lift, composite decking, standing seam metal roof, and full electrical. All structural components marine-grade. Does not include seawall work or dredging. Timeline: 4-6 weeks from permit approval.",
        defaultTerms: "This proposal is valid for 30 days. Payment schedule: 1/3 at contract signing, 1/3 at framing complete, 1/3 at final completion. Engineering and permit fees billed at cost. Lift equipment is special order — 3-4 week lead time."
    )
    
    // MARK: - 7. Rip Rap / Rock Revetment
    
    static let ripRapRevetment = SeedTemplate(
        name: "Rip Rap Revetment — 75 LF",
        sections: [
            SeedSection(name: "Site Work", items: [
                SeedItem(description: "Shoreline clearing and grading", qty: 1, price: 1500, unit: "ls"),
                SeedItem(description: "Mobilization — equipment transport", qty: 1, price: 2000, unit: "ls"),
            ]),
            SeedSection(name: "Seawall", items: [
                SeedItem(description: "Rip rap boulders — supply and place", qty: 75, price: 180, unit: "lf"),
                SeedItem(description: "Filter fabric underlayment", qty: 75, price: 8, unit: "lf"),
                SeedItem(description: "Gravel bedding layer", qty: 75, price: 15, unit: "lf"),
            ]),
            SeedSection(name: "Permits & Engineering", items: [
                SeedItem(description: "Environmental permit (DEP)", qty: 1, price: 1500, unit: "ea"),
                SeedItem(description: "Erosion control plan", qty: 1, price: 800, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Install rip rap rock revetment along 75 linear feet of shoreline for erosion control. Includes filter fabric, gravel bed, and boulder placement. Boulders sized per engineering spec. Does not include seawall, dock, or landscaping. Timeline: 1-2 weeks from permit approval.",
        defaultTerms: "This proposal is valid for 30 days. Payment: 50% at contract signing, 50% at completion. Actual rock quantities may vary slightly based on field conditions — final invoice adjusted accordingly."
    )
    
    // MARK: - 8. Piling Replacement
    
    static let pilingReplacement = SeedTemplate(
        name: "Piling Replacement — 4 Pilings",
        sections: [
            SeedSection(name: "Site Work", items: [
                SeedItem(description: "Temporary dock support / shoring", qty: 1, price: 800, unit: "ls"),
                SeedItem(description: "Old piling extraction and disposal", qty: 4, price: 350, unit: "ea"),
            ]),
            SeedSection(name: "Pilings", items: [
                SeedItem(description: "New pressure-treated pilings 10\" dia — supply and drive", qty: 4, price: 850, unit: "ea"),
                SeedItem(description: "Piling caps", qty: 4, price: 25, unit: "ea"),
                SeedItem(description: "Connection hardware (stainless)", qty: 4, price: 75, unit: "ea"),
            ]),
            SeedSection(name: "Labor", items: [
                SeedItem(description: "Pile driving crew and equipment", qty: 1, price: 2000, unit: "ls"),
            ]),
        ],
        defaultNotes: "Scope: Remove and replace 4 deteriorated pilings. Includes temporary support of existing dock structure during replacement. Existing framing and decking to be reconnected to new pilings. Scope assumes standard sand/mud bottom — rock or coquina may require change order. Timeline: 1-2 days.",
        defaultTerms: "This proposal is valid for 30 days. Payment: due on completion. If bottom conditions require specialized equipment (jetting, drilling), additional costs will be quoted before proceeding."
    )

    // MARK: - 9. Dock Accessories Package

    static let dockAccessories = SeedTemplate(
        name: "Dock Accessories Package",
        sections: [
            SeedSection(name: "Accessories", items: [
                SeedItem(description: "Fish cleaning station (fiberglass, with faucet)", qty: 1, price: 1200, unit: "ea"),
                SeedItem(description: "Kayak launch rack (aluminum, fold-down)", qty: 1, price: 950, unit: "ea"),
                SeedItem(description: "PWC lift (1,500 lb capacity)", qty: 1, price: 3500, unit: "ea"),
                SeedItem(description: "Dock box (large, fiberglass)", qty: 1, price: 450, unit: "ea"),
                SeedItem(description: "Dock cleats (stainless steel)", qty: 6, price: 45, unit: "ea"),
                SeedItem(description: "Dock bumpers (corner & side)", qty: 8, price: 35, unit: "ea"),
                SeedItem(description: "Dock ladder (aluminum, fold-up, 4-step)", qty: 1, price: 350, unit: "ea"),
                SeedItem(description: "Rod holders (flush mount, stainless)", qty: 4, price: 35, unit: "ea"),
            ]),
            SeedSection(name: "Electrical", items: [
                SeedItem(description: "LED dock lighting (low-voltage)", qty: 8, price: 85, unit: "ea"),
                SeedItem(description: "Underwater dock lights (green LED)", qty: 2, price: 250, unit: "ea"),
                SeedItem(description: "GFCI outlet (waterproof, dock-rated)", qty: 2, price: 175, unit: "ea"),
                SeedItem(description: "Low-voltage wiring and transformer", qty: 1, price: 400, unit: "ls"),
            ]),
            SeedSection(name: "Labor", items: [
                SeedItem(description: "Accessory installation labor", qty: 8, price: 85, unit: "hr"),
                SeedItem(description: "Electrical installation labor", qty: 4, price: 95, unit: "hr"),
            ]),
        ],
        defaultNotes: "Scope: Supply and install dock accessories on existing dock structure. Dock must be in good structural condition. Includes all mounting hardware (stainless steel). Electrical work by licensed marine electrician. Does not include dock repair, piling work, or boat lift installation. Timeline: 1-2 days.",
        defaultTerms: "This proposal is valid for 30 days. Payment: 50% at contract signing, 50% at completion. Accessories are ordered upon signed contract — typical lead time 1-2 weeks. Returns not accepted on installed accessories."
    )
}
