import SwiftUI
import WidgetKit

// MARK: - Stats Widget (Small + Medium)
// Shows open proposals, unpaid total, and overdue count at a glance.

struct StatsEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct StatsProvider: TimelineProvider {
    func placeholder(in _: Context) -> StatsEntry {
        StatsEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in _: Context, completion: @escaping (StatsEntry) -> Void) {
        let snapshot = WidgetAppGroup.readSnapshot() ?? .placeholder
        completion(StatsEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<StatsEntry>) -> Void) {
        let snapshot = WidgetAppGroup.readSnapshot() ?? .placeholder
        let entry = StatsEntry(date: .now, snapshot: snapshot)
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Small Widget View

struct StatsSmallView: View {
    let entry: StatsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.caption2)
                    .foregroundColor(Color.wAmber)
                Text("MMCC")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.snapshot.openProposalCount)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("open")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }

                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.caption2)
                        .foregroundColor(Color.wAmber)
                    Text(entry.snapshot.unpaidTotal)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }

                if entry.snapshot.overdueCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(Color.wStatusOverdue)
                        Text("\(entry.snapshot.overdueCount) overdue")
                            .font(.caption2)
                            .foregroundColor(Color.wStatusOverdue)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            Color.wNavy
        }
    }
}

// MARK: - Medium Widget View

struct StatsMediumView: View {
    let entry: StatsEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: stats column
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption2)
                        .foregroundColor(Color.wAmber)
                    Text("MMCC")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                statRow(
                    icon: "doc.text.fill",
                    tint: Color.wStatusSent,
                    value: "\(entry.snapshot.openProposalCount)",
                    label: "Open"
                )
                statRow(
                    icon: "dollarsign.circle.fill",
                    tint: Color.wAmber,
                    value: entry.snapshot.unpaidTotal,
                    label: "Unpaid"
                )
                statRow(
                    icon: "briefcase.fill",
                    tint: Color.wStatusAccepted,
                    value: "\(entry.snapshot.totalJobs)",
                    label: "Jobs"
                )
                if entry.snapshot.overdueCount > 0 {
                    statRow(
                        icon: "exclamationmark.triangle.fill",
                        tint: Color.wStatusOverdue,
                        value: "\(entry.snapshot.overdueCount)",
                        label: "Overdue"
                    )
                }
            }

            // Right: recent proposals
            VStack(alignment: .leading, spacing: 6) {
                Text("ACTIVE")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.4))

                if entry.snapshot.activeProposals.isEmpty {
                    Spacer()
                    Text("No active\nproposals")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.3))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ForEach(entry.snapshot.activeProposals.prefix(3), id: \.number) { prop in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.widgetStatusColor(for: prop.statusRaw))
                                .frame(width: 6, height: 6)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(prop.title)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text(prop.amount)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .monospacedDigit()
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(for: .widget) {
            Color.wNavy
        }
    }

    private func statRow(icon: String, tint: Color, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(tint)
                .frame(width: 14)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}

// MARK: - Widget Configuration

struct MMCCStatsWidget: Widget {
    let kind = "MMCCStatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatsProvider()) { entry in
            StatsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("MMCC Stats")
        .description("Open proposals, unpaid totals, and job count at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StatsWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: StatsEntry

    var body: some View {
        switch family {
        case .systemSmall:
            StatsSmallView(entry: entry)
        default:
            StatsMediumView(entry: entry)
        }
    }
}
