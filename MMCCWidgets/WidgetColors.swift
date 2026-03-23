import SwiftUI

// Widget-side color definitions (matches main app BrandTheme.swift)
extension Color {
    static let wNavy = Color(red: 18 / 255, green: 32 / 255, blue: 47 / 255)
    static let wNavyLight = Color(red: 28 / 255, green: 48 / 255, blue: 68 / 255)
    static let wAmber = Color(red: 175 / 255, green: 97 / 255, blue: 24 / 255)

    static let wStatusDraft = Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255)
    static let wStatusSent = Color(red: 50 / 255, green: 130 / 255, blue: 240 / 255)
    static let wStatusAccepted = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
    static let wStatusDeclined = Color(red: 255 / 255, green: 59 / 255, blue: 48 / 255)
    static let wStatusOverdue = Color(red: 255 / 255, green: 59 / 255, blue: 48 / 255)

    static func widgetStatusColor(for rawValue: String) -> Color {
        switch rawValue {
        case "draft": .wStatusDraft
        case "sent": .wStatusSent
        case "accepted": .wStatusAccepted
        case "declined", "overdue": .wStatusDeclined
        default: .wStatusDraft
        }
    }
}
