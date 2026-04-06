import SwiftUI

// MARK: - Brand Colors

extension Color {
    // Primary brand — warm terracotta inspired by PasangLagi, adapted for HVAC
    static let mmccNavy = Color(red: 18 / 255, green: 32 / 255, blue: 47 / 255)
    static let mmccNavyLight = Color(red: 28 / 255, green: 48 / 255, blue: 68 / 255)
    static let mmccNavyMid = Color(red: 38 / 255, green: 62 / 255, blue: 88 / 255)

    // Warm surface colors for cards (PasangLagi-inspired cream/sand tones)
    static let mmccSand = Color(red: 245 / 255, green: 240 / 255, blue: 232 / 255)
    static let mmccSandDark = Color(red: 58 / 255, green: 52 / 255, blue: 46 / 255)
    /// Adapts between light sand and dark sand based on color scheme
    static let mmccCardFill = Color("mmccCardFill", bundle: nil)

    // Status colors
    static let statusDraft = Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255)
    static let statusSent = Color(red: 50 / 255, green: 130 / 255, blue: 240 / 255)
    static let statusAccepted = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
    static let statusDeclined = Color(red: 255 / 255, green: 59 / 255, blue: 48 / 255)
    static let statusInvoiced = Color(red: 100 / 255, green: 80 / 255, blue: 200 / 255)
    static let statusOverdue = Color(red: 255 / 255, green: 59 / 255, blue: 48 / 255)
    static let statusPaid = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
    static let statusPartial = Color(red: 255 / 255, green: 149 / 255, blue: 0 / 255)
}

// MARK: - Status Color Helpers

extension ProposalStatus {
    var color: Color {
        switch self {
        case .draft: .statusDraft
        case .sent: .statusSent
        case .accepted: .statusAccepted
        case .declined: .statusDeclined
        case .invoiced: .statusInvoiced
        case .expired: .statusDraft
        }
    }

    var iconName: String {
        switch self {
        case .draft: "pencil.circle.fill"
        case .sent: "paperplane.circle.fill"
        case .accepted: "checkmark.circle.fill"
        case .declined: "xmark.circle.fill"
        case .invoiced: "doc.circle.fill"
        case .expired: "clock.badge.exclamationmark"
        }
    }
}

extension InvoiceStatus {
    var color: Color {
        switch self {
        case .draft: .statusDraft
        case .sent: .statusSent
        case .partiallyPaid: .statusPartial
        case .paid: .statusPaid
        case .overdue: .statusOverdue
        case .void: .statusDraft
        }
    }
}

// MARK: - Reusable Status Badge

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.15), in: .capsule)
    }
}

// MARK: - Card Background

/// Content-layer card fill for Liquid Glass apps.
/// Uses system grouped background — NOT .glassEffect() (glass is for navigation only).
/// Cards use solid fills so Liquid Glass toolbars/tab bars can float above content.
struct CardBackground: ViewModifier {
    var cornerRadius: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func cardBackground(cornerRadius: CGFloat = 14) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius))
    }
}

// MARK: - Metric Badge (PasangLagi-style rounded stat)

/// Compact metric badge like PasangLagi's duration/workers/materials badges.
struct MetricBadge: View {
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(tint)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Feature Grid Button (PasangLagi-style icon grid)

/// Icon + label button matching PasangLagi's feature grid pattern.
struct FeatureGridButton: View {
    let title: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                Text(title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String?
    let count: Int?

    init(_ title: String, icon: String? = nil, count: Int? = nil) {
        self.title = title
        self.icon = icon
        self.count = count
    }

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
            }
            Text(title)
                .font(.subheadline.weight(.semibold))
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundStyle(.secondary)
            if let count {
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.tint.opacity(0.15), in: .capsule)
                    .foregroundStyle(.tint)
            }
            Spacer()
        }
    }
}
