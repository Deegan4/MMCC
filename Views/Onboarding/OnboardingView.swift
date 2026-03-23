import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var logoAppeared = false
    @State private var textAppeared = false

    var body: some View {
        ZStack {
            // Hero dock photo as full background
            Image("HeroDock")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Dark gradient overlay for readability
            LinearGradient(
                colors: [
                    Color.black.opacity(0.85),
                    Color.black.opacity(0.5),
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.6),
                    Color.black.opacity(0.9),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                // MMCC 3D gold logo
                Image("MMCCLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 260, height: 260)
                    .shadow(color: .black.opacity(0.6), radius: 20, y: 10)
                    .opacity(logoAppeared ? 1 : 0)
                    .scaleEffect(logoAppeared ? 1 : 0.8)

                Spacer().frame(height: 32)

                // Tagline from website
                VStack(spacing: 8) {
                    Text("Your Project,")
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
                Text("Specializing in Marine Construction\nand Consulting Services")
                    .font(.system(size: 14, weight: .medium))
                    .tracking(1.5)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.mmccGold.opacity(0.9))
                    .opacity(textAppeared ? 1 : 0)

                Spacer().frame(height: 8)

                // Service area
                Text("Serving Southwest Florida")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .opacity(textAppeared ? 1 : 0)

                Spacer()

                // Gold accent line
                Capsule()
                    .fill(Color.mmccGold)
                    .frame(width: 60, height: 3)
                    .padding(.bottom, 20)

                // Get Started button — Liquid Glass with MMCC amber tint
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

                Spacer().frame(height: 16)

                // License number
                Text("CBC1253967")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.35))

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
        profile.city = "Cape Coral"
        profile.state = "FL"
        profile.defaultTaxRate = 7
        profile.defaultMarkup = 15
        profile.defaultPaymentTerms = .thirdThirdThird
        profile.defaultPermitJurisdiction = .leeCounty
        profile.defaultValidDays = 30
        profile.defaultTerms = "Payment: 1/3 at contract signing, 1/3 at midpoint, 1/3 at completion. Proposal valid for 30 days."
        profile.onboardingComplete = true
        modelContext.insert(profile)
        seedTemplates()
        try? modelContext.save()
    }

    private func seedTemplates() {
        for seed in MarineTemplates.all {
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

// MARK: - Brand Colors (extracted from morganmarinecc.com)

extension Color {
    /// MMCC brand amber (website sections): rgb(175, 97, 24) / #AF6118
    static let mmccAmber = Color(red: 175 / 255, green: 97 / 255, blue: 24 / 255)

    /// MMCC logo gold (3D logo text): rgb(205, 175, 100) / #CDAF64
    static let mmccGold = Color(red: 205 / 255, green: 175 / 255, blue: 100 / 255)
}
