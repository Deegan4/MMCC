import Foundation

// MARK: - Marine Section Category

enum MarineSection: String, Codable, CaseIterable, Identifiable {
    case pilings
    case framingStructure
    case decking
    case seawall
    case boatLift
    case electrical
    case accessories
    case permitsEngineering
    case siteWork
    case labor
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pilings: "Pilings"
        case .framingStructure: "Framing & Structure"
        case .decking: "Decking"
        case .seawall: "Seawall"
        case .boatLift: "Boat Lift"
        case .electrical: "Electrical"
        case .accessories: "Accessories"
        case .permitsEngineering: "Permits & Engineering"
        case .siteWork: "Site Work"
        case .labor: "Labor"
        case .other: "Other"
        }
    }

    var iconName: String {
        switch self {
        case .pilings: "arrow.down.to.line"
        case .framingStructure: "square.grid.3x3.topleft.filled"
        case .decking: "rectangle.split.3x3.fill"
        case .seawall: "water.waves"
        case .boatLift: "arrow.up.square"
        case .electrical: "bolt.fill"
        case .accessories: "wrench.and.screwdriver.fill"
        case .permitsEngineering: "doc.text.fill"
        case .siteWork: "shovel.fill"
        case .labor: "person.fill"
        case .other: "ellipsis.circle.fill"
        }
    }

    var defaultSortOrder: Int {
        switch self {
        case .siteWork: 0
        case .pilings: 1
        case .seawall: 2
        case .framingStructure: 3
        case .decking: 4
        case .boatLift: 5
        case .electrical: 6
        case .accessories: 7
        case .labor: 8
        case .permitsEngineering: 9
        case .other: 10
        }
    }
}

// MARK: - Waterway Type

enum WaterwayType: String, Codable, CaseIterable, Identifiable {
    case canal
    case river
    case intercoastal
    case openWater
    case lake
    case bay
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .canal: "Canal"
        case .river: "River"
        case .intercoastal: "Intercoastal"
        case .openWater: "Open Water"
        case .lake: "Lake"
        case .bay: "Bay"
        case .other: "Other"
        }
    }
}

// MARK: - Bottom Conditions

enum BottomCondition: String, Codable, CaseIterable, Identifiable {
    case sand
    case mud
    case rock
    case coquina
    case clay
    case mixed
    case unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sand: "Sand"
        case .mud: "Mud / Silt"
        case .rock: "Rock"
        case .coquina: "Coquina"
        case .clay: "Clay"
        case .mixed: "Mixed"
        case .unknown: "Unknown"
        }
    }
}

// MARK: - Site Access

enum SiteAccess: String, Codable, CaseIterable, Identifiable {
    case landOnly
    case waterOnly
    case both
    case bargeRequired

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .landOnly: "Land Access Only"
        case .waterOnly: "Water Access Only"
        case .both: "Land + Water Access"
        case .bargeRequired: "Barge Required"
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
    case thirdThirdThird  // Common in marine: 1/3 deposit, 1/3 midpoint, 1/3 completion
    case fiftyFifty        // 50% deposit, 50% completion

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dueOnReceipt: "Due on Receipt"
        case .net15: "Net 15"
        case .net30: "Net 30"
        case .net45: "Net 45"
        case .net60: "Net 60"
        case .thirdThirdThird: "1/3 Deposit, 1/3 Midpoint, 1/3 Completion"
        case .fiftyFifty: "50% Deposit, 50% Completion"
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
    case pilings
    case decking
    case framing
    case seawall
    case boatLift
    case electrical
    case accessories
    case permits
    case labor
    case siteWork
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pilings: "Pilings"
        case .decking: "Decking"
        case .framing: "Framing"
        case .seawall: "Seawall"
        case .boatLift: "Boat Lift"
        case .electrical: "Electrical"
        case .accessories: "Accessories"
        case .permits: "Permits & Engineering"
        case .labor: "Labor"
        case .siteWork: "Site Work"
        case .other: "Other"
        }
    }
}

// MARK: - Seawall Type

enum SeawallType: String, Codable, CaseIterable, Identifiable {
    case vinyl
    case concrete
    case steel
    case ripRap
    case wood
    case none
    case unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vinyl: "Vinyl Sheet Pile"
        case .concrete: "Concrete"
        case .steel: "Steel Sheet Pile"
        case .ripRap: "Rip Rap"
        case .wood: "Wood"
        case .none: "No Seawall"
        case .unknown: "Unknown"
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

// MARK: - Permit Jurisdiction

enum PermitJurisdiction: String, Codable, CaseIterable, Identifiable {
    case leeCounty
    case charlotteCounty
    case collierCounty
    case sarasotaCounty
    case manateeCounty
    case hillsboroughCounty
    case pinellasCounty
    case brevardCounty
    case duvalCounty
    case palmBeachCounty
    case browardCounty
    case miamiDadeCounty
    case otherFL
    case outOfState

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .leeCounty: "Lee County"
        case .charlotteCounty: "Charlotte County"
        case .collierCounty: "Collier County"
        case .sarasotaCounty: "Sarasota County"
        case .manateeCounty: "Manatee County"
        case .hillsboroughCounty: "Hillsborough County"
        case .pinellasCounty: "Pinellas County"
        case .brevardCounty: "Brevard County"
        case .duvalCounty: "Duval County"
        case .palmBeachCounty: "Palm Beach County"
        case .browardCounty: "Broward County"
        case .miamiDadeCounty: "Miami-Dade County"
        case .otherFL: "Other FL County"
        case .outOfState: "Out of State"
        }
    }
}
