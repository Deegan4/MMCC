import Foundation
import SwiftData

@Model
final class SavedItem {
    var id: UUID = UUID()
    var itemDescription: String = ""
    var defaultQty: Decimal = 1
    var defaultPrice: Decimal = 0
    var unit: String = "ea"
    var category: ItemCategory = ItemCategory.other
    var usageCount: Int = 0
    var lastUsedAt: Date?
    var qbItemID: String?
    var createdAt: Date = Date.now
    init() {}
    init(description: String, qty: Decimal = 1, price: Decimal, unit: String = "ea", category: ItemCategory) {
        self.itemDescription = description; self.defaultQty = qty; self.defaultPrice = price; self.unit = unit; self.category = category
    }
    func recordUsage() { usageCount += 1; lastUsedAt = .now }
}

@Model
final class SyncQueueItem {
    var id: UUID = UUID()
    var entityType: SyncEntityType = SyncEntityType.proposal
    var entityID: UUID = UUID()
    var action: SyncAction = SyncAction.create
    var retryCount: Int = 0
    var maxRetries: Int = 3
    var lastError: String?
    var createdAt: Date = Date.now
    init() {}
    init(entityType: SyncEntityType, entityID: UUID, action: SyncAction) {
        self.entityType = entityType; self.entityID = entityID; self.action = action
    }
    var canRetry: Bool { retryCount < maxRetries }
}
