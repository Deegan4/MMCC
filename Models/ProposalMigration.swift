import Foundation
import SwiftData

// MARK: - Schema Migration Plan
// Maps the old "Estimate" entity names to the new "Proposal" names
// so existing user data is preserved across the rename.

enum MMCCMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    // Lightweight migration — SwiftData handles the rename via originalName
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}

// MARK: - V1 Schema (original "Estimate" names)

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            V1Estimate.self,
            V1EstimateSection.self,
            V1EstimateLineItem.self,
        ]
    }

    @Model
    final class V1Estimate {
        var id: UUID = UUID()
        var number: Int = 0
        var title: String = ""
        var qbEstimateID: String?
        var qbDocNumber: String?
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now
        init() {}
    }

    @Model
    final class V1EstimateSection {
        var id: UUID = UUID()
        var name: String = ""
        var sortOrder: Int = 0
        init() {}
    }

    @Model
    final class V1EstimateLineItem {
        var id: UUID = UUID()
        var itemDescription: String = ""
        var quantity: Decimal = 1
        var unitPrice: Decimal = 0
        init() {}
    }
}

// MARK: - V2 Schema (renamed to "Proposal")

enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            Proposal.self,
            ProposalSection.self,
            ProposalLineItem.self,
        ]
    }
}
