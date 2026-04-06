import Foundation

/// HVAC job templates with real residential/commercial pricing (2025-2026).
/// Contractor customizes to their market on first use.
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
        let unit: String
    }

    // MARK: - All Templates

    static let all: [TemplateDef] = [
        acReplacementBasic,
        acReplacementPremium,
        furnaceReplacement,
        heatPumpConversion,
        ductworkNewConstruction,
        ductRepairAndSeal,
        miniSplitMultiZone,
        commercialRTU5Ton,
        thermostatUpgrade,
        refrigerantRecharge,
    ]

    // ──────────────────────────────────────────
    // 1. AC Replacement — Basic (14 SEER2)
    // ──────────────────────────────────────────
    static let acReplacementBasic = TemplateDef(
        name: "AC Replacement — 3-Ton 14 SEER2",
        sections: [
            SectionDef(name: "Equipment", items: [
                ItemDef(description: "3-ton 14 SEER2 condenser unit", qty: 1, price: 1800, unit: "ea"),
                ItemDef(description: "Matching evaporator coil", qty: 1, price: 650, unit: "ea"),
                ItemDef(description: "Standard thermostat", qty: 1, price: 125, unit: "ea"),
            ]),
            SectionDef(name: "Refrigerant & Piping", items: [
                ItemDef(description: "R-410A refrigerant charge", qty: 1, price: 300, unit: "LS"),
                ItemDef(description: "Line set — copper", qty: 25, price: 15, unit: "LF"),
            ]),
            SectionDef(name: "Electrical", items: [
                ItemDef(description: "Disconnect and whip", qty: 1, price: 175, unit: "ea"),
                ItemDef(description: "Electrical connections", qty: 1, price: 300, unit: "LS"),
            ]),
            SectionDef(name: "Labor", items: [
                ItemDef(description: "Removal and disposal of old unit", qty: 1, price: 400, unit: "LS"),
                ItemDef(description: "Installation labor", qty: 6, price: 90, unit: "hr"),
                ItemDef(description: "Start-up and commissioning", qty: 1, price: 200, unit: "LS"),
            ]),
            SectionDef(name: "Permits & Inspection", items: [
                ItemDef(description: "Mechanical permit", qty: 1, price: 225, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Replace existing AC condenser and evaporator coil. Includes refrigerant charge, thermostat, and electrical. Does not include ductwork or air handler.\n\nTimeline: 1 day installation.",
        defaultTerms: "Payment: 50% deposit, 50% at completion. Proposal valid for 30 days. 10-year parts warranty. 1-year labor warranty."
    )

    // ──────────────────────────────────────────
    // 2. AC Replacement — Premium (18+ SEER2)
    // ──────────────────────────────────────────
    static let acReplacementPremium = TemplateDef(
        name: "AC Replacement — 3-Ton 18 SEER2 Variable Speed",
        sections: [
            SectionDef(name: "Equipment", items: [
                ItemDef(description: "3-ton 18 SEER2 variable-speed condenser", qty: 1, price: 3800, unit: "ea"),
                ItemDef(description: "Variable-speed evaporator coil", qty: 1, price: 1200, unit: "ea"),
                ItemDef(description: "Wi-Fi smart thermostat", qty: 1, price: 300, unit: "ea"),
                ItemDef(description: "Surge protector", qty: 1, price: 125, unit: "ea"),
            ]),
            SectionDef(name: "Refrigerant & Piping", items: [
                ItemDef(description: "R-410A refrigerant charge", qty: 1, price: 400, unit: "LS"),
                ItemDef(description: "Line set — insulated copper", qty: 30, price: 18, unit: "LF"),
                ItemDef(description: "Condensate drain with safety switch", qty: 1, price: 150, unit: "LS"),
            ]),
            SectionDef(name: "Electrical", items: [
                ItemDef(description: "Disconnect and whip", qty: 1, price: 185, unit: "ea"),
                ItemDef(description: "Electrical connections", qty: 1, price: 400, unit: "LS"),
            ]),
            SectionDef(name: "Labor", items: [
                ItemDef(description: "Old unit removal and disposal", qty: 1, price: 500, unit: "LS"),
                ItemDef(description: "Installation labor", qty: 8, price: 95, unit: "hr"),
                ItemDef(description: "Start-up, charge, and commissioning", qty: 1, price: 300, unit: "LS"),
            ]),
            SectionDef(name: "Permits & Inspection", items: [
                ItemDef(description: "Mechanical permit", qty: 1, price: 250, unit: "ea"),
                ItemDef(description: "Manual J load calculation", qty: 1, price: 250, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Premium AC replacement with variable-speed technology for maximum efficiency and comfort. Includes smart thermostat and surge protector.\n\nTimeline: 1 day installation.\n\nSEER2 rating qualifies for utility rebates — check with your power company.",
        defaultTerms: "Payment: 50% deposit, 50% at completion. Proposal valid for 30 days. 10-year parts warranty. 1-year labor warranty."
    )

    // ──────────────────────────────────────────
    // 3. Furnace Replacement
    // ──────────────────────────────────────────
    static let furnaceReplacement = TemplateDef(
        name: "Furnace Replacement — 80K BTU 96% AFUE",
        sections: [
            SectionDef(name: "Equipment", items: [
                ItemDef(description: "80K BTU 96% AFUE two-stage gas furnace", qty: 1, price: 2400, unit: "ea"),
                ItemDef(description: "Programmable thermostat", qty: 1, price: 200, unit: "ea"),
            ]),
            SectionDef(name: "Materials & Supplies", items: [
                ItemDef(description: "PVC flue venting", qty: 25, price: 16, unit: "LF"),
                ItemDef(description: "Gas piping and connections", qty: 1, price: 400, unit: "LS"),
                ItemDef(description: "Condensate drain and neutralizer", qty: 1, price: 150, unit: "LS"),
            ]),
            SectionDef(name: "Labor", items: [
                ItemDef(description: "Old furnace removal and disposal", qty: 1, price: 350, unit: "LS"),
                ItemDef(description: "Installation labor", qty: 8, price: 90, unit: "hr"),
                ItemDef(description: "Start-up and combustion analysis", qty: 1, price: 200, unit: "LS"),
            ]),
            SectionDef(name: "Permits & Inspection", items: [
                ItemDef(description: "Mechanical + gas permit", qty: 1, price: 300, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Replace existing furnace with new high-efficiency 96% AFUE gas furnace. Includes PVC venting, gas connections, and condensate drain. Does not include AC, ductwork, or gas line extension.\n\nTimeline: 1 day.",
        defaultTerms: "Payment: 50% deposit, 50% at completion and inspection. Proposal valid for 30 days."
    )

    // ──────────────────────────────────────────
    // 4. Heat Pump Conversion
    // ──────────────────────────────────────────
    static let heatPumpConversion = TemplateDef(
        name: "Heat Pump Conversion — 3-Ton",
        sections: [
            SectionDef(name: "Equipment", items: [
                ItemDef(description: "3-ton heat pump condenser — 16 SEER2", qty: 1, price: 3200, unit: "ea"),
                ItemDef(description: "Air handler with electric backup heat", qty: 1, price: 2200, unit: "ea"),
                ItemDef(description: "Smart thermostat with heat pump control", qty: 1, price: 300, unit: "ea"),
            ]),
            SectionDef(name: "Refrigerant & Piping", items: [
                ItemDef(description: "R-410A refrigerant charge", qty: 1, price: 400, unit: "LS"),
                ItemDef(description: "Line set — insulated copper", qty: 30, price: 18, unit: "LF"),
            ]),
            SectionDef(name: "Electrical", items: [
                ItemDef(description: "New breaker and wiring for heat pump", qty: 1, price: 550, unit: "LS"),
                ItemDef(description: "Disconnect box", qty: 1, price: 175, unit: "ea"),
            ]),
            SectionDef(name: "Labor", items: [
                ItemDef(description: "Old system removal and disposal", qty: 1, price: 600, unit: "LS"),
                ItemDef(description: "Installation labor", qty: 12, price: 95, unit: "hr"),
                ItemDef(description: "Start-up and commissioning", qty: 1, price: 300, unit: "LS"),
            ]),
            SectionDef(name: "Permits & Inspection", items: [
                ItemDef(description: "Mechanical permit", qty: 1, price: 300, unit: "ea"),
                ItemDef(description: "Manual J load calculation", qty: 1, price: 250, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Convert from gas furnace/AC to electric heat pump system. Includes heat pump condenser, air handler with backup heat, smart thermostat, and new electrical circuit.\n\nMay qualify for federal tax credits and utility rebates.\n\nTimeline: 1-2 days.",
        defaultTerms: "Payment: 1/3 at signing, 1/3 at rough-in, 1/3 at completion. Proposal valid for 30 days."
    )

    // ──────────────────────────────────────────
    // 5. Ductwork — New Construction
    // ──────────────────────────────────────────
    static let ductworkNewConstruction = TemplateDef(
        name: "Ductwork — New Construction 2,000 SF",
        sections: [
            SectionDef(name: "Ductwork", items: [
                ItemDef(description: "Supply trunk line — galvanized metal", qty: 50, price: 28, unit: "LF"),
                ItemDef(description: "Supply branch runs — insulated flex", qty: 180, price: 10, unit: "LF"),
                ItemDef(description: "Return trunk — rigid metal", qty: 30, price: 25, unit: "LF"),
                ItemDef(description: "Supply boots and fittings", qty: 12, price: 25, unit: "ea"),
                ItemDef(description: "Supply registers", qty: 12, price: 30, unit: "ea"),
                ItemDef(description: "Return air grilles (20x20)", qty: 3, price: 50, unit: "ea"),
            ]),
            SectionDef(name: "Insulation", items: [
                ItemDef(description: "Duct sealing — mastic + UL tape", qty: 1, price: 500, unit: "LS"),
            ]),
            SectionDef(name: "Labor", items: [
                ItemDef(description: "Rough-in installation — 2 technicians", qty: 16, price: 85, unit: "hr"),
                ItemDef(description: "Trim-out (registers, grilles)", qty: 4, price: 85, unit: "hr"),
                ItemDef(description: "Duct leakage test", qty: 1, price: 250, unit: "LS"),
            ]),
        ],
        defaultNotes: "Scope: Complete ductwork installation for new construction, approximately 2,000 SF. Includes supply and return runs, registers, grilles, and duct sealing. Duct leakage test included for code compliance.\n\nCoordinated with general contractor schedule.",
        defaultTerms: "Payment: 50% at rough-in, 50% at trim-out. Proposal valid for 30 days."
    )

    // ──────────────────────────────────────────
    // 6. Duct Repair & Seal
    // ──────────────────────────────────────────
    static let ductRepairAndSeal = TemplateDef(
        name: "Duct Repair & Sealing",
        sections: [
            SectionDef(name: "Ductwork", items: [
                ItemDef(description: "Replace damaged flex duct sections", qty: 40, price: 12, unit: "LF"),
                ItemDef(description: "Repair disconnected duct joints", qty: 4, price: 75, unit: "ea"),
                ItemDef(description: "Replace crushed or torn duct boots", qty: 3, price: 45, unit: "ea"),
            ]),
            SectionDef(name: "Insulation", items: [
                ItemDef(description: "Duct sealing — mastic on all accessible joints", qty: 1, price: 650, unit: "LS"),
                ItemDef(description: "Re-insulate exposed ductwork", qty: 30, price: 6, unit: "LF"),
            ]),
            SectionDef(name: "Labor", items: [
                ItemDef(description: "Diagnostic and duct inspection", qty: 1, price: 175, unit: "LS"),
                ItemDef(description: "Repair labor", qty: 6, price: 85, unit: "hr"),
                ItemDef(description: "Duct leakage test (before and after)", qty: 1, price: 250, unit: "LS"),
            ]),
        ],
        defaultNotes: "Scope: Repair damaged and disconnected ductwork, seal all accessible joints with mastic, and re-insulate exposed sections. Before/after leakage test included to verify improvement.\n\nTimeline: 1 day.",
        defaultTerms: "Payment: due at completion. Proposal valid for 30 days."
    )

    // ──────────────────────────────────────────
    // 7. Mini-Split Multi-Zone
    // ──────────────────────────────────────────
    static let miniSplitMultiZone = TemplateDef(
        name: "Mini-Split — 3-Zone Ductless System",
        sections: [
            SectionDef(name: "Equipment", items: [
                ItemDef(description: "Multi-zone outdoor condenser (36K BTU)", qty: 1, price: 3200, unit: "ea"),
                ItemDef(description: "Wall-mounted indoor head (12K BTU)", qty: 3, price: 650, unit: "ea"),
                ItemDef(description: "Wireless remotes", qty: 3, price: 0, unit: "ea"),
            ]),
            SectionDef(name: "Refrigerant & Piping", items: [
                ItemDef(description: "Line sets — pre-charged, insulated", qty: 75, price: 15, unit: "LF"),
                ItemDef(description: "Line set covers (exterior)", qty: 30, price: 8, unit: "LF"),
                ItemDef(description: "Condensate drain lines", qty: 3, price: 85, unit: "ea"),
            ]),
            SectionDef(name: "Electrical", items: [
                ItemDef(description: "Dedicated circuit from panel", qty: 1, price: 550, unit: "LS"),
                ItemDef(description: "Disconnect box", qty: 1, price: 125, unit: "ea"),
            ]),
            SectionDef(name: "Labor", items: [
                ItemDef(description: "Installation labor — 2 technicians", qty: 12, price: 95, unit: "hr"),
                ItemDef(description: "Wall penetrations and sealing (3)", qty: 3, price: 125, unit: "ea"),
                ItemDef(description: "Start-up and commissioning", qty: 1, price: 250, unit: "LS"),
            ]),
            SectionDef(name: "Permits & Inspection", items: [
                ItemDef(description: "Mechanical/electrical permit", qty: 1, price: 250, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Install 3-zone ductless mini-split system with one outdoor unit and three wall-mounted indoor heads. Each zone independently controlled. Includes line sets with exterior covers, electrical, and condensate drains.\n\nTimeline: 1-2 days.",
        defaultTerms: "Payment: 50% at equipment order, 50% at completion. Proposal valid for 30 days."
    )

    // ──────────────────────────────────────────
    // 8. Commercial RTU — 5-Ton
    // ──────────────────────────────────────────
    static let commercialRTU5Ton = TemplateDef(
        name: "Commercial RTU — 5-Ton Replacement",
        sections: [
            SectionDef(name: "Equipment", items: [
                ItemDef(description: "5-ton commercial RTU — gas/electric", qty: 1, price: 5500, unit: "ea"),
                ItemDef(description: "Roof curb adapter", qty: 1, price: 450, unit: "ea"),
                ItemDef(description: "Commercial thermostat", qty: 1, price: 350, unit: "ea"),
            ]),
            SectionDef(name: "Materials & Supplies", items: [
                ItemDef(description: "Gas piping connections", qty: 1, price: 400, unit: "LS"),
                ItemDef(description: "Duct transitions", qty: 1, price: 550, unit: "LS"),
                ItemDef(description: "Roof flashing", qty: 1, price: 300, unit: "LS"),
            ]),
            SectionDef(name: "Labor", items: [
                ItemDef(description: "Crane rental", qty: 1, price: 1800, unit: "LS"),
                ItemDef(description: "Old unit removal and disposal", qty: 1, price: 600, unit: "LS"),
                ItemDef(description: "Installation labor", qty: 12, price: 100, unit: "hr"),
                ItemDef(description: "Start-up and commissioning", qty: 1, price: 400, unit: "LS"),
            ]),
            SectionDef(name: "Permits & Inspection", items: [
                ItemDef(description: "Commercial mechanical permit", qty: 1, price: 400, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Replace existing rooftop unit with new 5-ton gas/electric RTU. Includes crane, roof curb, gas connections, and duct transitions.\n\nTimeline: 1 day.",
        defaultTerms: "Payment: 50% deposit, 50% at completion. Proposal valid for 30 days."
    )

    // ──────────────────────────────────────────
    // 9. Thermostat Upgrade
    // ──────────────────────────────────────────
    static let thermostatUpgrade = TemplateDef(
        name: "Smart Thermostat Upgrade",
        sections: [
            SectionDef(name: "Equipment", items: [
                ItemDef(description: "Smart thermostat (Ecobee/Honeywell/Nest)", qty: 1, price: 300, unit: "ea"),
                ItemDef(description: "C-wire adapter (if needed)", qty: 1, price: 45, unit: "ea"),
            ]),
            SectionDef(name: "Labor", items: [
                ItemDef(description: "Installation and wiring", qty: 1, price: 150, unit: "LS"),
                ItemDef(description: "Wi-Fi setup and app configuration", qty: 1, price: 75, unit: "LS"),
                ItemDef(description: "System test and calibration", qty: 1, price: 75, unit: "LS"),
            ]),
        ],
        defaultNotes: "Scope: Replace existing thermostat with smart Wi-Fi thermostat. Includes wiring (C-wire adapter if needed), Wi-Fi setup, and app configuration on customer's phone.\n\nTimeline: 1-2 hours.",
        defaultTerms: "Payment: due at completion. Proposal valid for 30 days."
    )

    // ──────────────────────────────────────────
    // 10. Refrigerant Recharge & Leak Repair
    // ──────────────────────────────────────────
    static let refrigerantRecharge = TemplateDef(
        name: "Refrigerant Recharge & Leak Repair",
        sections: [
            SectionDef(name: "Refrigerant & Piping", items: [
                ItemDef(description: "R-410A refrigerant (per lb)", qty: 5, price: 65, unit: "lb"),
                ItemDef(description: "Leak detection — electronic and UV dye", qty: 1, price: 175, unit: "LS"),
                ItemDef(description: "Braze leak repair (per joint)", qty: 2, price: 185, unit: "ea"),
            ]),
            SectionDef(name: "Labor", items: [
                ItemDef(description: "Diagnostic and system evaluation", qty: 1, price: 125, unit: "LS"),
                ItemDef(description: "Repair labor", qty: 3, price: 95, unit: "hr"),
                ItemDef(description: "Nitrogen pressure test", qty: 1, price: 150, unit: "LS"),
                ItemDef(description: "Vacuum and recharge", qty: 1, price: 200, unit: "LS"),
            ]),
        ],
        defaultNotes: "Scope: Locate refrigerant leak(s), repair via brazing, pressure test, evacuate, and recharge system to manufacturer specs. Refrigerant quantity estimated — actual amount billed at per-pound rate.\n\nIf evaporator or condenser coil replacement is needed, a separate proposal will be provided.",
        defaultTerms: "Payment: due at completion. Proposal valid for 30 days. Repair warranty: 90 days parts and labor."
    )
}
