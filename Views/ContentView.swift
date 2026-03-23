import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var profiles: [BusinessProfile]
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    var body: some View {
        Group {
            if let profile = profiles.first, profile.onboardingComplete {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
