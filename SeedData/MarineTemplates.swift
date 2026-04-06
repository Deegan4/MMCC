import Foundation

/// HVAC job seed templates with real residential/commercial pricing (2025-2026).
/// Contractor customizes to their market on first use.
enum HVACTemplates {

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
        residentialACReplacement,
        residentialFullSystem,
        miniSplitInstall,
        commercialRTU,
        ductworkReplacement,
        furnaceInstall,
        maintenanceAgreement,
        indoorAirQuality,
        heatPumpInstall,
    ]

    // MARK: - 1. Residential AC Replacement (3-Ton Split System)

    static let residentialACReplacement = SeedTemplate(
        name: "Residential AC Replacement — 3-Ton Split",
        sections: [
            SeedSection(name: "Equipment", items: [
                SeedItem(description: "3-ton 16 SEER2 condenser unit", qty: 1, price: 2800, unit: "ea"),
                SeedItem(description: "Matching evaporator coil", qty: 1, price: 850, unit: "ea"),
                SeedItem(description: "Programmable thermostat (Wi-Fi)", qty: 1, price: 250, unit: "ea"),
            ]),
            SeedSection(name: "Refrigerant & Piping", items: [
                SeedItem(description: "R-410A refrigerant charge", qty: 1, price: 350, unit: "ls"),
                SeedItem(description: "Line set — insulated copper", qty: 25, price: 18, unit: "lf"),
                SeedItem(description: "Condensate drain line and trap", qty: 1, price: 125, unit: "ls"),
            ]),
            SeedSection(name: "Electrical", items: [
                SeedItem(description: "Disconnect box and whip", qty: 1, price: 185, unit: "ea"),
                SeedItem(description: "Electrical connections and wiring", qty: 1, price: 350, unit: "ls"),
            ]),
            SeedSection(name: "Labor", items: [
                SeedItem(description: "System removal and disposal", qty: 1, price: 500, unit: "ls"),
                SeedItem(description: "Installation labor — 2 technicians", qty: 8, price: 95, unit: "hr"),
                SeedItem(description: "Start-up, charge, and commissioning", qty: 1, price: 250, unit: "ls"),
            ]),
            SeedSection(name: "Permits & Inspection", items: [
                SeedItem(description: "Mechanical permit", qty: 1, price: 250, unit: "ea"),
                SeedItem(description: "City/county inspection", qty: 1, price: 150, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Remove existing outdoor condenser and indoor evaporator coil. Install new 3-ton 16 SEER2 split system with matching coil, new thermostat, and refrigerant charge. Includes electrical disconnect and all connections. Does not include ductwork modifications, attic insulation, or structural work. Timeline: 1 day installation.",
        defaultTerms: "This proposal is valid for 30 days. Payment: 50% deposit at contract signing, 50% at completion and inspection. Equipment carries manufacturer's 10-year parts warranty. Installation warranty: 1 year labor. Permit fees are estimates and may vary."
    )

    // MARK: - 2. Residential Full HVAC System

    static let residentialFullSystem = SeedTemplate(
        name: "Residential Full HVAC — 4-Ton System",
        sections: [
            SeedSection(name: "Equipment", items: [
                SeedItem(description: "4-ton 18 SEER2 variable-speed condenser", qty: 1, price: 4200, unit: "ea"),
                SeedItem(description: "Matching variable-speed air handler", qty: 1, price: 2800, unit: "ea"),
                SeedItem(description: "Smart thermostat (Ecobee/Honeywell)", qty: 1, price: 350, unit: "ea"),
                SeedItem(description: "UV germicidal light for coil", qty: 1, price: 450, unit: "ea"),
                SeedItem(description: "Surge protector (condenser)", qty: 1, price: 125, unit: "ea"),
            ]),
            SeedSection(name: "Ductwork", items: [
                SeedItem(description: "Supply ductwork — flex duct, insulated", qty: 150, price: 12, unit: "lf"),
                SeedItem(description: "Return ductwork — rigid metal", qty: 30, price: 22, unit: "lf"),
                SeedItem(description: "Supply registers and grilles", qty: 10, price: 35, unit: "ea"),
                SeedItem(description: "Return air grilles", qty: 2, price: 55, unit: "ea"),
                SeedItem(description: "Duct sealing (mastic & tape)", qty: 1, price: 450, unit: "ls"),
            ]),
            SeedSection(name: "Refrigerant & Piping", items: [
                SeedItem(description: "R-410A refrigerant charge", qty: 1, price: 450, unit: "ls"),
                SeedItem(description: "Line set — insulated copper", qty: 35, price: 18, unit: "lf"),
                SeedItem(description: "Condensate drain with safety switch", qty: 1, price: 175, unit: "ls"),
            ]),
            SeedSection(name: "Electrical", items: [
                SeedItem(description: "Disconnect box and whip", qty: 1, price: 185, unit: "ea"),
                SeedItem(description: "Breaker and electrical wiring", qty: 1, price: 550, unit: "ls"),
                SeedItem(description: "Thermostat wiring", qty: 1, price: 150, unit: "ls"),
            ]),
            SeedSection(name: "Labor", items: [
                SeedItem(description: "Old system removal and disposal", qty: 1, price: 750, unit: "ls"),
                SeedItem(description: "Installation labor — 2-3 technicians", qty: 16, price: 95, unit: "hr"),
                SeedItem(description: "Start-up, charge, and commissioning", qty: 1, price: 350, unit: "ls"),
            ]),
            SeedSection(name: "Permits & Inspection", items: [
                SeedItem(description: "Mechanical permit", qty: 1, price: 350, unit: "ea"),
                SeedItem(description: "Energy code compliance (Manual J load calc)", qty: 1, price: 300, unit: "ea"),
                SeedItem(description: "City/county inspection", qty: 1, price: 150, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Complete HVAC system replacement including condenser, air handler, ductwork, thermostat, and all electrical. Includes Manual J load calculation for energy code compliance. Old system removal and disposal included. Timeline: 2-3 days. Home must be accessible during installation.",
        defaultTerms: "This proposal is valid for 30 days. Payment schedule: 1/3 at contract signing, 1/3 at rough-in, 1/3 at completion and inspection. Equipment carries manufacturer's 10-year parts warranty. Installation warranty: 1 year labor."
    )

    // MARK: - 3. Mini-Split Install (Single Zone)

    static let miniSplitInstall = SeedTemplate(
        name: "Mini-Split Install — Single Zone 12K BTU",
        sections: [
            SeedSection(name: "Equipment", items: [
                SeedItem(description: "12,000 BTU ductless mini-split — outdoor unit", qty: 1, price: 1200, unit: "ea"),
                SeedItem(description: "Wall-mounted indoor head unit", qty: 1, price: 650, unit: "ea"),
                SeedItem(description: "Wireless remote control", qty: 1, price: 0, unit: "ea"),
            ]),
            SeedSection(name: "Refrigerant & Piping", items: [
                SeedItem(description: "Pre-charged line set", qty: 25, price: 15, unit: "lf"),
                SeedItem(description: "Line set cover (outdoor)", qty: 15, price: 8, unit: "lf"),
                SeedItem(description: "Condensate drain line", qty: 1, price: 85, unit: "ls"),
            ]),
            SeedSection(name: "Electrical", items: [
                SeedItem(description: "Dedicated 20A circuit from panel", qty: 1, price: 450, unit: "ls"),
                SeedItem(description: "Disconnect box", qty: 1, price: 125, unit: "ea"),
            ]),
            SeedSection(name: "Labor", items: [
                SeedItem(description: "Installation labor", qty: 6, price: 95, unit: "hr"),
                SeedItem(description: "Wall penetration and sealing", qty: 1, price: 150, unit: "ls"),
                SeedItem(description: "Start-up and commissioning", qty: 1, price: 150, unit: "ls"),
            ]),
            SeedSection(name: "Permits & Inspection", items: [
                SeedItem(description: "Mechanical/electrical permit", qty: 1, price: 200, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Install single-zone ductless mini-split system. Includes wall-mounted indoor unit, outdoor condenser, line set with cover, dedicated electrical circuit, and condensate drain. One wall penetration required. Does not include patching/painting interior wall beyond installation area. Timeline: 1 day.",
        defaultTerms: "This proposal is valid for 30 days. Payment: 50% deposit at order, 50% at completion. Equipment carries manufacturer's 7-year warranty. Installation warranty: 1 year labor."
    )

    // MARK: - 4. Commercial Rooftop Unit (RTU) Replacement

    static let commercialRTU = SeedTemplate(
        name: "Commercial RTU Replacement — 10-Ton",
        sections: [
            SeedSection(name: "Equipment", items: [
                SeedItem(description: "10-ton commercial rooftop unit (RTU) — gas/electric", qty: 1, price: 8500, unit: "ea"),
                SeedItem(description: "Roof curb adapter (if needed)", qty: 1, price: 650, unit: "ea"),
                SeedItem(description: "Programmable commercial thermostat", qty: 1, price: 450, unit: "ea"),
            ]),
            SeedSection(name: "Materials & Supplies", items: [
                SeedItem(description: "Gas piping and connections", qty: 1, price: 550, unit: "ls"),
                SeedItem(description: "Duct transition and plenum connections", qty: 1, price: 750, unit: "ls"),
                SeedItem(description: "Roof flashing and weatherproofing", qty: 1, price: 400, unit: "ls"),
            ]),
            SeedSection(name: "Electrical", items: [
                SeedItem(description: "Electrical disconnect and wiring", qty: 1, price: 650, unit: "ls"),
                SeedItem(description: "Control wiring — thermostat to RTU", qty: 1, price: 350, unit: "ls"),
            ]),
            SeedSection(name: "Labor", items: [
                SeedItem(description: "Crane rental — RTU removal and placement", qty: 1, price: 2500, unit: "ls"),
                SeedItem(description: "Old unit removal and disposal", qty: 1, price: 800, unit: "ls"),
                SeedItem(description: "Installation labor — 3 technicians", qty: 16, price: 105, unit: "hr"),
                SeedItem(description: "Start-up, charge, and commissioning", qty: 1, price: 500, unit: "ls"),
            ]),
            SeedSection(name: "Permits & Inspection", items: [
                SeedItem(description: "Commercial mechanical permit", qty: 1, price: 500, unit: "ea"),
                SeedItem(description: "Inspection (mechanical + gas)", qty: 1, price: 250, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Remove existing rooftop unit and install new 10-ton gas/electric RTU. Includes crane rental, roof curb adapter, gas and electrical connections, and duct transitions. Roof penetration resealed and weatherproofed. Does not include ductwork below roof level, structural modifications, or roof repair beyond flashing. Timeline: 1-2 days.",
        defaultTerms: "This proposal is valid for 30 days. Payment: 50% deposit at equipment order, 50% at completion. Equipment warranty per manufacturer terms. Installation warranty: 1 year parts and labor."
    )

    // MARK: - 5. Ductwork Replacement

    static let ductworkReplacement = SeedTemplate(
        name: "Ductwork Replacement — Residential",
        sections: [
            SeedSection(name: "Ductwork", items: [
                SeedItem(description: "Insulated flex duct — supply runs", qty: 200, price: 10, unit: "lf"),
                SeedItem(description: "Rigid metal trunk line", qty: 40, price: 25, unit: "lf"),
                SeedItem(description: "Supply plenums and transitions", qty: 2, price: 250, unit: "ea"),
                SeedItem(description: "Return air plenum — metal", qty: 1, price: 350, unit: "ea"),
                SeedItem(description: "Supply registers and grilles", qty: 12, price: 35, unit: "ea"),
                SeedItem(description: "Return air grilles", qty: 3, price: 55, unit: "ea"),
                SeedItem(description: "Duct hangers and supports", qty: 1, price: 300, unit: "ls"),
            ]),
            SeedSection(name: "Insulation", items: [
                SeedItem(description: "Duct board / rigid insulation wraps", qty: 1, price: 450, unit: "ls"),
                SeedItem(description: "Duct sealing — mastic and UL tape", qty: 1, price: 500, unit: "ls"),
            ]),
            SeedSection(name: "Labor", items: [
                SeedItem(description: "Old ductwork removal and disposal", qty: 1, price: 800, unit: "ls"),
                SeedItem(description: "Installation labor — 2-3 technicians", qty: 16, price: 85, unit: "hr"),
                SeedItem(description: "Duct leakage testing", qty: 1, price: 250, unit: "ls"),
            ]),
            SeedSection(name: "Permits & Inspection", items: [
                SeedItem(description: "Mechanical permit (if required)", qty: 1, price: 200, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Complete ductwork replacement including supply and return runs, plenums, registers, and grilles. All ductwork sealed with mastic per code. Duct leakage test performed after installation. Does not include HVAC equipment replacement, attic insulation, or drywall repair. Timeline: 2-3 days.",
        defaultTerms: "This proposal is valid for 30 days. Payment: 50% at contract signing, 50% at completion. Ductwork warranty: 10 years on materials. Installation warranty: 1 year labor."
    )

    // MARK: - 6. Gas Furnace Install

    static let furnaceInstall = SeedTemplate(
        name: "Gas Furnace Install — 80K BTU",
        sections: [
            SeedSection(name: "Equipment", items: [
                SeedItem(description: "80,000 BTU 96% AFUE gas furnace", qty: 1, price: 2200, unit: "ea"),
                SeedItem(description: "Matching evaporator coil (for future AC)", qty: 1, price: 750, unit: "ea"),
                SeedItem(description: "Programmable thermostat", qty: 1, price: 200, unit: "ea"),
            ]),
            SeedSection(name: "Materials & Supplies", items: [
                SeedItem(description: "Flue venting — PVC direct vent", qty: 25, price: 18, unit: "lf"),
                SeedItem(description: "Gas piping and connections", qty: 1, price: 450, unit: "ls"),
                SeedItem(description: "Condensate drain (high-efficiency)", qty: 1, price: 125, unit: "ls"),
            ]),
            SeedSection(name: "Electrical", items: [
                SeedItem(description: "Electrical wiring and connections", qty: 1, price: 350, unit: "ls"),
            ]),
            SeedSection(name: "Labor", items: [
                SeedItem(description: "Old furnace removal and disposal", qty: 1, price: 400, unit: "ls"),
                SeedItem(description: "Installation labor — 2 technicians", qty: 8, price: 95, unit: "hr"),
                SeedItem(description: "Start-up, combustion analysis, and commissioning", qty: 1, price: 250, unit: "ls"),
            ]),
            SeedSection(name: "Permits & Inspection", items: [
                SeedItem(description: "Mechanical + gas permit", qty: 1, price: 300, unit: "ea"),
                SeedItem(description: "Inspection", qty: 1, price: 150, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Remove existing furnace and install new 80K BTU high-efficiency gas furnace with direct vent flue. Includes evaporator coil for future AC connection, gas piping, and thermostat. Combustion analysis performed at start-up. Does not include AC condenser, ductwork modifications, or gas line extension from meter. Timeline: 1 day.",
        defaultTerms: "This proposal is valid for 30 days. Payment: 50% deposit, 50% at completion and inspection. Manufacturer's 10-year heat exchanger warranty. Installation warranty: 1 year labor."
    )

    // MARK: - 7. Maintenance Agreement

    static let maintenanceAgreement = SeedTemplate(
        name: "HVAC Maintenance — Annual Agreement",
        sections: [
            SeedSection(name: "Labor", items: [
                SeedItem(description: "Spring AC tune-up — clean coils, check charge, inspect", qty: 1, price: 175, unit: "ea"),
                SeedItem(description: "Fall heating tune-up — clean burners, check heat exchanger", qty: 1, price: 175, unit: "ea"),
            ]),
            SeedSection(name: "Materials & Supplies", items: [
                SeedItem(description: "Air filters (2 changes included)", qty: 2, price: 25, unit: "ea"),
                SeedItem(description: "Condensate drain treatment tablets", qty: 2, price: 10, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Annual HVAC maintenance agreement includes 2 scheduled visits (spring and fall), filter changes, coil cleaning, refrigerant check, electrical inspection, and safety testing. Priority scheduling and 15% discount on repairs included. Does not include parts or refrigerant beyond standard check. Agreement auto-renews annually.",
        defaultTerms: "Payment: due at time of first visit, or billed monthly. Cancel anytime with 30-day notice. Emergency service available 24/7 for agreement members at standard rates."
    )

    // MARK: - 8. Indoor Air Quality Package

    static let indoorAirQuality = SeedTemplate(
        name: "Indoor Air Quality — Full Package",
        sections: [
            SeedSection(name: "Equipment", items: [
                SeedItem(description: "Whole-home air purifier (electronic)", qty: 1, price: 1200, unit: "ea"),
                SeedItem(description: "UV germicidal light — coil-mounted", qty: 1, price: 450, unit: "ea"),
                SeedItem(description: "Whole-home humidifier (bypass)", qty: 1, price: 550, unit: "ea"),
                SeedItem(description: "MERV-13 media filter cabinet", qty: 1, price: 350, unit: "ea"),
            ]),
            SeedSection(name: "Materials & Supplies", items: [
                SeedItem(description: "Water supply line for humidifier", qty: 1, price: 150, unit: "ls"),
                SeedItem(description: "Duct modifications for installation", qty: 1, price: 250, unit: "ls"),
                SeedItem(description: "Electrical connections", qty: 1, price: 200, unit: "ls"),
            ]),
            SeedSection(name: "Labor", items: [
                SeedItem(description: "Installation labor", qty: 6, price: 95, unit: "hr"),
            ]),
        ],
        defaultNotes: "Scope: Install complete indoor air quality package including electronic air purifier, UV germicidal coil light, bypass humidifier, and MERV-13 media filter. All components integrated with existing HVAC system. Includes water line for humidifier. Does not include ductwork cleaning or HVAC system repairs. Timeline: 1 day.",
        defaultTerms: "This proposal is valid for 30 days. Payment: due at completion. Product warranties per manufacturer terms. Installation warranty: 1 year labor."
    )

    // MARK: - 9. Heat Pump Install

    static let heatPumpInstall = SeedTemplate(
        name: "Heat Pump System — 3-Ton, Dual Fuel",
        sections: [
            SeedSection(name: "Equipment", items: [
                SeedItem(description: "3-ton 17 SEER2 heat pump condenser", qty: 1, price: 3500, unit: "ea"),
                SeedItem(description: "Variable-speed air handler with backup heat strip", qty: 1, price: 2400, unit: "ea"),
                SeedItem(description: "Smart thermostat with dual-fuel control", qty: 1, price: 350, unit: "ea"),
            ]),
            SeedSection(name: "Refrigerant & Piping", items: [
                SeedItem(description: "R-410A refrigerant charge", qty: 1, price: 400, unit: "ls"),
                SeedItem(description: "Line set — insulated copper", qty: 30, price: 18, unit: "lf"),
                SeedItem(description: "Condensate drain with safety switch", qty: 1, price: 150, unit: "ls"),
            ]),
            SeedSection(name: "Electrical", items: [
                SeedItem(description: "Disconnect box and whip", qty: 1, price: 185, unit: "ea"),
                SeedItem(description: "Electrical wiring (condenser + air handler)", qty: 1, price: 650, unit: "ls"),
            ]),
            SeedSection(name: "Labor", items: [
                SeedItem(description: "Old system removal and disposal", qty: 1, price: 650, unit: "ls"),
                SeedItem(description: "Installation labor — 2-3 technicians", qty: 12, price: 95, unit: "hr"),
                SeedItem(description: "Start-up, charge, and commissioning", qty: 1, price: 350, unit: "ls"),
            ]),
            SeedSection(name: "Permits & Inspection", items: [
                SeedItem(description: "Mechanical permit", qty: 1, price: 300, unit: "ea"),
                SeedItem(description: "Energy code compliance (Manual J)", qty: 1, price: 300, unit: "ea"),
                SeedItem(description: "Inspection", qty: 1, price: 150, unit: "ea"),
            ]),
        ],
        defaultNotes: "Scope: Remove existing system and install new 3-ton heat pump with variable-speed air handler and backup electric heat. Includes smart thermostat with dual-fuel staging. Manual J load calculation for code compliance. Does not include ductwork replacement or modifications. Timeline: 1-2 days.",
        defaultTerms: "This proposal is valid for 30 days. Payment: 1/3 deposit, 1/3 at rough-in, 1/3 at completion. Manufacturer's 10-year parts warranty. Installation warranty: 1 year labor."
    )
}
