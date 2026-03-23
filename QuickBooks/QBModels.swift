import Foundation

// MARK: - QB Query Response Wrapper

struct QBQueryResponse<T: Codable>: Codable {
    let QueryResponse: QBQueryInner<T>

    struct QBQueryInner<U: Codable>: Codable {
        let startPosition: Int?
        let maxResults: Int?

        // Dynamic keys — decoded manually
        let items: [U]

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: DynamicCodingKey.self)
            startPosition = try container.decodeIfPresent(Int.self, forKey: .init("startPosition"))
            maxResults = try container.decodeIfPresent(Int.self, forKey: .init("maxResults"))
            // Intuit wraps results in a key matching the entity name (Customer, Item, TaxRate, etc.)
            // Try known keys
            for key in ["Customer", "Item", "TaxRate"] {
                if let decoded = try? container.decode([U].self, forKey: .init(key)) {
                    items = decoded
                    return
                }
            }
            items = []
        }

        func encode(to encoder: Encoder) throws {
            // Not needed — response-only struct
        }
    }
}

private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(_ string: String) { self.stringValue = string }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { self.intValue = intValue; self.stringValue = "\(intValue)" }
}

// MARK: - Customer DTO

struct QBCustomerDTO: Codable {
    let Id: String?
    let SyncToken: String?
    let DisplayName: String?
    let PrimaryPhone: QBPhone?
    let PrimaryEmailAddr: QBEmail?
    let BillAddr: QBAddress?
    let Notes: String?
    let Active: Bool?

    struct QBPhone: Codable { let FreeFormNumber: String? }
    struct QBEmail: Codable { let Address: String? }
    struct QBAddress: Codable {
        let Line1: String?
        let City: String?
        let CountrySubDivisionCode: String?
        let PostalCode: String?
    }
}

// MARK: - Item (Product/Service) DTO

struct QBItemDTO: Codable {
    let Id: String?
    let Name: String?
    let Description: String?
    let UnitPrice: Decimal?
    let ItemType: String? // Service, Inventory, NonInventory

    enum CodingKeys: String, CodingKey {
        case Id, Name, Description, UnitPrice, Active
        case ItemType = "Type"
    }
    let Active: Bool?
}

// MARK: - Tax Rate DTO

struct QBTaxRateDTO: Codable {
    let Id: String?
    let Name: String?
    let RateValue: Decimal?
    let Active: Bool?
}

// MARK: - QB Entity Create/Update Response

struct QBEntityResponse<T: Codable>: Codable {
    // Intuit wraps the response in a key matching the entity type
    let entity: T

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        for key in ["Customer", "Estimate", "Invoice", "Payment"] {
            if let decoded = try? container.decode(T.self, forKey: .init(key)) {
                entity = decoded
                return
            }
        }
        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "No known entity key found"))
    }

    func encode(to encoder: Encoder) throws {}
}

// MARK: - QB Created Entity (minimal response fields we need)

struct QBCreatedEntity: Codable {
    let Id: String
    let SyncToken: String?
    let DocNumber: String?
}

// MARK: - Estimate/Invoice Line Types for QB

struct QBLine: Codable {
    let DetailType: String
    let Amount: Decimal?
    let Description: String?
    let SalesItemLineDetail: QBSalesItemDetail?
    let SubTotalLineDetail: QBSubTotalDetail?

    struct QBSalesItemDetail: Codable {
        let Qty: Decimal?
        let UnitPrice: Decimal?
        let ItemRef: QBRef?
    }

    struct QBSubTotalDetail: Codable {}
}

struct QBRef: Codable {
    let value: String
    let name: String?

    init(value: String, name: String? = nil) {
        self.value = value
        self.name = name
    }
}

// MARK: - Linked Transaction (for invoice→estimate link)

struct QBLinkedTxn: Codable {
    let TxnId: String
    let TxnType: String
}
