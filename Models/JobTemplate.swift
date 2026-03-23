import Foundation
import SwiftData

@Model
final class JobTemplate {
    var id: UUID = UUID()
    var name: String = ""
    var defaultNotes: String = ""
    var defaultTerms: String = ""
    var defaultMarkup: Decimal = 0
    var defaultTaxRate: Decimal = 0
    var usageCount: Int = 0
    var isSystemTemplate: Bool = false
    @Relationship(deleteRule: .cascade, inverse: \TemplateSection.template) var sections: [TemplateSection]?
    var createdAt: Date = Date.now
    init() {}
    init(name: String) { self.name = name }
    var sortedSections: [TemplateSection] { (sections ?? []).sorted { $0.sortOrder < $1.sortOrder } }

    var estimatedSubtotal: Decimal {
        (sections ?? []).reduce(.zero) { total, section in
            total + section.sectionSubtotal
        }
    }

    var estimatedTotal: Decimal {
        let sub = estimatedSubtotal
        let markupAmt = defaultMarkup > 0 ? sub * (defaultMarkup / 100) : 0
        let afterMarkup = sub + markupAmt
        let taxAmt = defaultTaxRate > 0 ? afterMarkup * (defaultTaxRate / 100) : 0
        return afterMarkup + taxAmt
    }

    /// Deep-copy this template into a new JobTemplate, inserting it into the given context.
    @discardableResult
    func duplicate(in context: ModelContext) -> JobTemplate {
        let copy = JobTemplate(name: "\(name) (Copy)")
        copy.defaultNotes = defaultNotes
        copy.defaultTerms = defaultTerms
        copy.defaultMarkup = defaultMarkup
        copy.defaultTaxRate = defaultTaxRate
        copy.isSystemTemplate = false
        for section in sortedSections {
            let newSection = TemplateSection(name: section.name, sortOrder: section.sortOrder)
            for item in section.sortedItems {
                let newItem = TemplateItem(description: item.itemDescription, qty: item.defaultQty, price: item.defaultPrice, unit: item.unit)
                newItem.sortOrder = item.sortOrder
                if newSection.items == nil { newSection.items = [] }
                newSection.items?.append(newItem)
            }
            if copy.sections == nil { copy.sections = [] }
            copy.sections?.append(newSection)
        }
        context.insert(copy)
        return copy
    }
}

@Model
final class TemplateSection {
    var id: UUID = UUID()
    var name: String = ""
    var sortOrder: Int = 0
    var template: JobTemplate?
    @Relationship(deleteRule: .cascade, inverse: \TemplateItem.section) var items: [TemplateItem]?
    init(name: String = "", sortOrder: Int = 0) { self.name = name; self.sortOrder = sortOrder }
    var sortedItems: [TemplateItem] { (items ?? []).sorted { $0.sortOrder < $1.sortOrder } }
    var sectionSubtotal: Decimal {
        (items ?? []).reduce(.zero) { $0 + $1.defaultQty * $1.defaultPrice }
    }
}

@Model
final class TemplateItem {
    var id: UUID = UUID()
    var itemDescription: String = ""
    var defaultQty: Decimal = 1
    var defaultPrice: Decimal = 0
    var unit: String = "ea"
    var sortOrder: Int = 0
    var section: TemplateSection?
    init() {}
    init(description: String, qty: Decimal, price: Decimal, unit: String = "ea") {
        self.itemDescription = description; self.defaultQty = qty; self.defaultPrice = price; self.unit = unit
    }
}
