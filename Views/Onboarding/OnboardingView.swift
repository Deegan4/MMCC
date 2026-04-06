import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var logoAppeared = false
    @State private var textAppeared = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color.mmccNavy,
                    Color.mmccNavyMid,
                    Color.mmccNavy,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                // App icon
                Image(systemName: "fan.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.mmccAmber)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                    .opacity(logoAppeared ? 1 : 0)
                    .scaleEffect(logoAppeared ? 1 : 0.8)

                Spacer().frame(height: 32)

                // Tagline
                VStack(spacing: 8) {
                    Text("HVAC Invoices,")
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .italic()
                    Text("Made Simple")
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .italic()
                }
                .foregroundStyle(.white)
                .opacity(textAppeared ? 1 : 0)
                .offset(y: textAppeared ? 0 : 20)

                Spacer().frame(height: 12)

                // Subtitle
                Text("Estimates & Invoices\nfor HVAC Contractors")
                    .font(.system(size: 14, weight: .medium))
                    .tracking(1.5)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.mmccGold.opacity(0.9))
                    .opacity(textAppeared ? 1 : 0)

                Spacer()

                // Accent line
                Capsule()
                    .fill(Color.mmccGold)
                    .frame(width: 60, height: 3)
                    .padding(.bottom, 20)

                // Get Started button
                Button {
                    completeOnboarding()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .tint(Color.mmccAmber)
                .cardBackground(cornerRadius: 14)
                .padding(.horizontal, 40)

                Spacer().frame(height: 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                logoAppeared = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                textAppeared = true
            }
        }
    }

    private func completeOnboarding() {
        let profile = BusinessProfile()
        profile.defaultTaxRate = 7
        profile.defaultMarkup = 15
        profile.defaultPaymentTerms = .net30
        profile.defaultValidDays = 30
        profile.defaultTerms = "Payment: 50% deposit at contract signing, 50% at completion and inspection. Proposal valid for 30 days."
        profile.onboardingComplete = true
        modelContext.insert(profile)
        seedTemplates()
        try? modelContext.save()
    }

    private func seedTemplates() {
        for seed in HVACTemplates.all {
            let template = JobTemplate(name: seed.name)
            template.isSystemTemplate = true
            template.defaultNotes = seed.defaultNotes
            template.defaultTerms = seed.defaultTerms
            for (sIndex, seedSection) in seed.sections.enumerated() {
                let section = TemplateSection(name: seedSection.name, sortOrder: sIndex)
                for (iIndex, seedItem) in seedSection.items.enumerated() {
                    let item = TemplateItem(description: seedItem.description, qty: seedItem.qty, price: seedItem.price, unit: seedItem.unit)
                    item.sortOrder = iIndex
                    if section.items == nil { section.items = [] }
                    section.items?.append(item)
                }
                if template.sections == nil { template.sections = [] }
                template.sections?.append(section)
            }
            modelContext.insert(template)
        }
    }
}

// MARK: - Brand Colors

extension Color {
    /// MMCC brand amber: rgb(175, 97, 24) / #AF6118
    static let mmccAmber = Color(red: 175 / 255, green: 97 / 255, blue: 24 / 255)

    /// MMCC logo gold: rgb(205, 175, 100) / #CDAF64
    static let mmccGold = Color(red: 205 / 255, green: 175 / 255, blue: 100 / 255)
}
