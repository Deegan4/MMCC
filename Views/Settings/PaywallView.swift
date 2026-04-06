import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    @State private var purchasing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                    featureGrid
                    pricingCards
                    purchaseButton
                    restoreButton
                    legalText
                }
                .padding()
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("MMCC Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.mmccAmber)

            Text("Unlock MMCC Pro")
                .font(.title2.weight(.bold))

            Text("Unlimited proposals, invoices, and QuickBooks sync for your HVAC business.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Feature Grid

    private var featureGrid: some View {
        VStack(spacing: 0) {
            featureRow("Proposals / month", free: "5", pro: "Unlimited")
            featureRow("Invoices / month", free: "3", pro: "Unlimited")
            featureRow("Customers", free: "10", pro: "Unlimited")
            featureRow("Saved Items", free: "20", pro: "Unlimited")
            featureRow("Templates", free: "3 custom", pro: "Unlimited")
            featureRow("QuickBooks Sync", free: nil, pro: "checkmark")
            featureRow("Your Logo on PDF", free: nil, pro: "checkmark")
            featureRow("CSV Export", free: nil, pro: "checkmark")
            featureRow("Milestone Splits", free: nil, pro: "checkmark")
        }
        .cardBackground(cornerRadius: 14)
    }

    private func featureRow(_ feature: String, free: String?, pro: String) -> some View {
        HStack {
            Text(feature)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Free column
            Group {
                if let free {
                    Text(free)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.tertiary)
                } else {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }
            }
            .frame(width: 60)

            // Pro column
            Group {
                if pro == "checkmark" {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.mmccAmber)
                } else {
                    Text(pro)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.mmccAmber)
                }
            }
            .frame(width: 70)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Pricing Cards

    private var pricingCards: some View {
        HStack(spacing: 12) {
            if let monthly = subscriptionManager.monthlyProduct {
                pricingCard(
                    product: monthly,
                    title: "Monthly",
                    badge: nil
                )
            }
            if let annual = subscriptionManager.annualProduct {
                pricingCard(
                    product: annual,
                    title: "Annual",
                    badge: "Save 33%"
                )
            }
        }
    }

    private func pricingCard(product: Product, title: String, badge: String?) -> some View {
        let isSelected = selectedProduct?.id == product.id

        return Button {
            selectedProduct = product
        } label: {
            VStack(spacing: 6) {
                if let badge {
                    Text(badge)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.mmccAmber, in: .capsule)
                }

                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(product.displayPrice)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.mmccAmber)

                Text(product.subscription?.subscriptionPeriod.displayUnit ?? "")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                if product.subscription?.introductoryOffer != nil {
                    Text("1 week free trial")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .cardBackground(cornerRadius: 14)
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.mmccAmber : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase

    private var purchaseButton: some View {
        Button {
            guard let product = selectedProduct ?? subscriptionManager.annualProduct else { return }
            purchasing = true
            Task {
                do {
                    try await subscriptionManager.purchase(product)
                    if subscriptionManager.isPro {
                        dismiss()
                    }
                } catch {
                    // Error shown via subscriptionManager.errorMessage
                }
                purchasing = false
            }
        } label: {
            Group {
                if purchasing || subscriptionManager.isLoading {
                    ProgressView()
                } else {
                    Text("Start Free Trial")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .tint(Color.mmccAmber)
        .buttonStyle(.borderedProminent)
        .disabled(purchasing || subscriptionManager.isLoading)

        // Error display
        .overlay(alignment: .bottom) {
            if let error = subscriptionManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 8)
                    .offset(y: 24)
            }
        }
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button {
            Task { await subscriptionManager.restorePurchases() }
        } label: {
            Text("Restore Purchases")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Legal

    private var legalText: some View {
        Text("Subscription auto-renews. Cancel anytime in Settings > Apple ID > Subscriptions.")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }
}

// MARK: - Subscription Period Display

extension Product.SubscriptionPeriod {
    var displayUnit: String {
        switch unit {
        case .month: "per month"
        case .year: "per year"
        case .week: "per week"
        case .day: "per day"
        @unknown default: ""
        }
    }
}
