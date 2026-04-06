import Foundation
import SwiftData

@Model
final class BusinessProfile {
    var businessName: String = ""
    var phone: String = ""
    var email: String = ""
    var street: String = ""
    var city: String = ""
    var state: String = ""
    var zip: String = ""
    var licenseNumber: String = ""
    @Attribute(.externalStorage) var logoData: Data?
    var defaultTaxRate: Decimal = 0.0
    var defaultMarkup: Decimal = 0.0
    var defaultPaymentTerms: PaymentTerms = PaymentTerms.net30
    var defaultTerms: String = ""
    var defaultValidDays: Int = 30
    var qbConnected: Bool = false
    var qbRealmID: String?
    var qbAccessToken: String?
    var qbRefreshToken: String?
    var qbTokenExpiry: Date?
    var googleDriveConnected: Bool = false
    var googleDriveFolderID: String?
    var onboardingComplete: Bool = false
    var createdAt: Date = Date.now
    init() {}

    var formattedAddress: String {
        [street, city, state, zip]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
