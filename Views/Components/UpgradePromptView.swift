import SwiftUI

/// Compact inline prompt shown when a free-tier limit is reached.
/// Drop into any view that needs to gate creation behind Pro.
struct UpgradePromptView: View {
    let message: String
    @State private var showingPaywall = false

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.title3)
                .foregroundStyle(Color.mmccAmber)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingPaywall = true
            } label: {
                Text("Upgrade to Pro")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
            }
            .tint(Color.mmccAmber)
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .cardBackground(cornerRadius: 14)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

/// Small banner variant for inline use in lists/forms.
struct UpgradePromptBanner: View {
    let text: String
    @State private var showingPaywall = false

    var body: some View {
        Button {
            showingPaywall = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundStyle(Color.mmccAmber)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Upgrade")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.mmccAmber)
            }
            .padding(10)
            .background(Color.mmccAmber.opacity(0.1), in: .rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}
