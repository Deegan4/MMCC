import Foundation
import Observation
import StoreKit

/// Manages StoreKit 2 subscriptions for MMCC Pro.
/// Source of truth: Transaction.currentEntitlements.
/// Caches to UserDefaults for offline resilience.
@Observable
@MainActor
final class SubscriptionManager {
    // MARK: - Product IDs

    static let monthlyID = "com.mmcc.pro.monthly"
    static let annualID = "com.mmcc.pro.annual"
    static let groupID = "MMCC Pro"
    private static let proEntitlementCacheKey = "mmcc_pro_entitlement_cached"

    // MARK: - State

    private(set) var products: [Product] = []
    private(set) var purchasedProductID: String?
    private(set) var expirationDate: Date?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var isPro: Bool {
        purchasedProductID != nil
    }

    var tier: SubscriptionTier {
        isPro ? .pro : .free
    }

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyID }
    }

    var annualProduct: Product? {
        products.first { $0.id == Self.annualID }
    }

    // MARK: - Private

    @ObservationIgnored
    private var updateListenerTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        // Restore cached state for immediate offline access
        if UserDefaults.standard.bool(forKey: Self.proEntitlementCacheKey) {
            purchasedProductID = "cached"
        }
    }

    // MARK: - Start

    func start() async {
        await loadProducts()
        await checkEntitlements()
        listenForTransactionUpdates()
    }

    // MARK: - Products

    private func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: [Self.monthlyID, Self.annualID])
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Failed to load subscription options."
        }
    }

    // MARK: - Entitlements

    func checkEntitlements() async {
        var foundProductID: String?
        var foundExpiration: Date?

        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else { continue }
            if transaction.productID == Self.monthlyID || transaction.productID == Self.annualID {
                foundProductID = transaction.productID
                foundExpiration = transaction.expirationDate
                break
            }
        }

        purchasedProductID = foundProductID
        expirationDate = foundExpiration
        UserDefaults.standard.set(foundProductID != nil, forKey: Self.proEntitlementCacheKey)
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case let .success(verification):
            guard case let .verified(transaction) = verification else {
                errorMessage = "Purchase could not be verified."
                return
            }
            await transaction.finish()
            purchasedProductID = transaction.productID
            expirationDate = transaction.expirationDate
            UserDefaults.standard.set(true, forKey: Self.proEntitlementCacheKey)

        case .userCancelled:
            break

        case .pending:
            errorMessage = "Purchase is pending approval."

        @unknown default:
            errorMessage = "An unknown error occurred."
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await checkEntitlements()
            if !isPro {
                errorMessage = "No active subscription found."
            }
        } catch {
            errorMessage = "Could not restore purchases."
        }
    }

    // MARK: - Transaction Updates

    private func listenForTransactionUpdates() {
        updateListenerTask?.cancel()
        updateListenerTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard case let .verified(transaction) = result else { continue }
                await transaction.finish()
                await self?.checkEntitlements()
            }
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }
}
