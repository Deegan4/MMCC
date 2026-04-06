import Foundation

// MARK: - HVAC Section Category

enum HVACSection: String, Codable, CaseIterable, Identifiable {
    case equipment
    case ductwork
    case refrigerant
    case electrical
    case controls
    case insulation
    case permits
    case labor
    case materials
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .equipment: "Equipment"
        case .ductwork: "Ductwork"
        case .refrigerant: "Refrigerant & Piping"
        case .electrical: "Electrical"
        case .controls: "Controls & Thermostats"
        case .insulation: "Insulation"
        case .permits: "Permits & Inspection"
        case .labor: "Labor"
        case .materials: "Materials & Supplies"
        case .other: "Other"
        }
    }

    var iconName: String {
        switch self {
        case .equipment: "fan.fill"
        case .ductwork: "wind"
        case .refrigerant: "snowflake"
        case .electrical: "bolt.fill"
        case .controls: "thermometer.medium"
        case .insulation: "square.stack.3d.up.fill"
        case .permits: "doc.text.fill"
        case .labor: "person.fill"
        case .materials: "shippingbox.fill"
        case .other: "ellipsis.circle.fill"
        }
    }

    var defaultSortOrder: Int {
        switch self {
        case .equipment: 0
        case .ductwork: 1
        case .refrigerant: 2
        case .electrical: 3
        case .controls: 4
        case .insulation: 5
        case .materials: 6
        case .labor: 7
        case .permits: 8
        case .other: 9
        }
    }
}

// MARK: - HVAC System Type

enum SystemType: String, Codable, CaseIterable, Identifiable {
    case centralSplit
    case packageUnit
    case miniSplit
    case ductlessMiniSplit
    case heatPump
    case furnace
    case boiler
    case geothermal
    case ptac
    case vrf
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .centralSplit: "Central Split System"
        case .packageUnit: "Package Unit"
        case .miniSplit: "Mini-Split"
        case .ductlessMiniSplit: "Ductless Mini-Split"
        case .heatPump: "Heat Pump"
        case .furnace: "Furnace"
        case .boiler: "Boiler"
        case .geothermal: "Geothermal"
        case .ptac: "PTAC"
        case .vrf: "VRF System"
        case .other: "Other"
        }
    }
}

// MARK: - Service Type

enum ServiceType: String, Codable, CaseIterable, Identifiable {
    case newInstall
    case replacement
    case repair
    case maintenance
    case inspection
    case ductCleaning
    case retrofit
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .newInstall: "New Installation"
        case .replacement: "Replacement"
        case .repair: "Repair"
        case .maintenance: "Maintenance"
        case .inspection: "Inspection"
        case .ductCleaning: "Duct Cleaning"
        case .retrofit: "Retrofit / Upgrade"
        case .other: "Other"
        }
    }
}

// MARK: - Property Type

enum PropertyType: String, Codable, CaseIterable, Identifiable {
    case residential
    case commercial
    case multiFamily
    case industrial
    case newConstruction
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .residential: "Residential"
        case .commercial: "Commercial"
        case .multiFamily: "Multi-Family"
        case .industrial: "Industrial"
        case .newConstruction: "New Construction"
        case .other: "Other"
        }
    }
}

// MARK: - Proposal Status

enum ProposalStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case sent
    case accepted
    case declined
    case invoiced
    case expired

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .draft: "Draft"
        case .sent: "Sent"
        case .accepted: "Accepted"
        case .declined: "Declined"
        case .invoiced: "Invoiced"
        case .expired: "Expired"
        }
    }

    var isActive: Bool {
        switch self {
        case .draft, .sent, .accepted: true
        default: false
        }
    }
}

// MARK: - Invoice Status

enum InvoiceStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case sent
    case partiallyPaid
    case paid
    case overdue
    case void

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .draft: "Draft"
        case .sent: "Sent"
        case .partiallyPaid: "Partially Paid"
        case .paid: "Paid"
        case .overdue: "Overdue"
        case .void: "Void"
        }
    }
}

// MARK: - Payment Terms

enum PaymentTerms: String, Codable, CaseIterable, Identifiable {
    case dueOnReceipt
    case net15
    case net30
    case net45
    case net60
    case fiftyFifty        // 50% deposit, 50% completion
    case thirdThirdThird   // 1/3 deposit, 1/3 midpoint, 1/3 completion

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dueOnReceipt: "Due on Receipt"
        case .net15: "Net 15"
        case .net30: "Net 30"
        case .net45: "Net 45"
        case .net60: "Net 60"
        case .fiftyFifty: "50% Deposit, 50% Completion"
        case .thirdThirdThird: "1/3 Deposit, 1/3 Midpoint, 1/3 Completion"
        }
    }
}

// MARK: - Payment Method

enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case cash
    case check
    case zelle
    case venmo
    case card
    case ach
    case financing
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cash: "Cash"
        case .check: "Check"
        case .zelle: "Zelle"
        case .venmo: "Venmo"
        case .card: "Card"
        case .ach: "ACH / Bank Transfer"
        case .financing: "Financing"
        case .other: "Other"
        }
    }
}

// MARK: - Subscription Tier

enum SubscriptionTier: String, Codable, CaseIterable, Identifiable, Sendable {
    case free
    case pro

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .free: "Free"
        case .pro: "Pro"
        }
    }

    /// Max proposals per calendar month (nil = unlimited)
    var proposalLimit: Int? {
        self == .free ? 5 : nil
    }

    /// Max invoices per calendar month (nil = unlimited)
    var invoiceLimit: Int? {
        self == .free ? 3 : nil
    }

    /// Max total customers (nil = unlimited)
    var customerLimit: Int? {
        self == .free ? 10 : nil
    }

    /// Max total saved items (nil = unlimited)
    var savedItemLimit: Int? {
        self == .free ? 20 : nil
    }

    /// Max user-created templates (nil = unlimited)
    var templateLimit: Int? {
        self == .free ? 3 : nil
    }

    var canSyncQuickBooks: Bool { self == .pro }
    var canRemoveWatermark: Bool { self == .pro }
    var canExportCSV: Bool { self == .pro }
    var canUseMilestoneSplits: Bool { self == .pro }
    var canUseCustomLogo: Bool { self == .pro }
}

// MARK: - QB Sync

enum QBSyncStatus: String, Codable {
    case notConnected
    case connected
    case syncing
    case error
    case queued
}

enum SyncAction: String, Codable {
    case create
    case update
}

enum SyncEntityType: String, Codable {
    case customer
    case proposal
    case invoice
    case payment
}

// MARK: - Saved Item Category

enum ItemCategory: String, Codable, CaseIterable, Identifiable {
    case equipment
    case ductwork
    case refrigerant
    case electrical
    case controls
    case insulation
    case permits
    case labor
    case materials
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .equipment: "Equipment"
        case .ductwork: "Ductwork"
        case .refrigerant: "Refrigerant & Piping"
        case .electrical: "Electrical"
        case .controls: "Controls & Thermostats"
        case .insulation: "Insulation"
        case .permits: "Permits & Inspection"
        case .labor: "Labor"
        case .materials: "Materials & Supplies"
        case .other: "Other"
        }
    }
}

// MARK: - Permit Status (per section)

enum PermitStatus: String, Codable, CaseIterable, Identifiable {
    case none
    case applied
    case pending
    case approved
    case denied

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: "No Permit Needed"
        case .applied: "Applied"
        case .pending: "Pending Review"
        case .approved: "Approved"
        case .denied: "Denied"
        }
    }

    var iconName: String {
        switch self {
        case .none: "minus.circle"
        case .applied: "paperplane.fill"
        case .pending: "clock.fill"
        case .approved: "checkmark.seal.fill"
        case .denied: "xmark.seal.fill"
        }
    }

    var tintColor: String {
        switch self {
        case .none: "secondary"
        case .applied: "blue"
        case .pending: "orange"
        case .approved: "green"
        case .denied: "red"
        }
    }
}

