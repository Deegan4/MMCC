import SwiftUI
import WidgetKit

// MARK: - Proposals Widget (Medium + Lock Screen)
// Shows active proposals list or lock screen unpaid summary.

struct ProposalsEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct ProposalsProvider: TimelineProvider {
    func placeholder(in _: Context) -> ProposalsEntry {
        ProposalsEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in _: Context, completion: @escaping (ProposalsEntry) -> Void) {
        let snapshot = WidgetAppGroup.readSnapshot() ?? .placeholder
        completion(ProposalsEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<ProposalsEntry>) -> Void) {
        let snapshot = WidgetAppGroup.readSnapshot() ?? .placeholder
        let entry = ProposalsEntry(date: .now, snapshot: snapshot)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Lock Screen (Inline)

struct ProposalsInlineView: View {
    let entry: ProposalsEntry

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.text.fill")
            Text("\(entry.snapshot.openProposalCount) open")
            Text("·")
            Text(entry.snapshot.unpaidTotal)
        }
    }
}

// MARK: - Lock Screen (Circular)

struct ProposalsCircularView: View {
    let entry: ProposalsEntry

    var body: some View {
        Gauge(
            value: Double(entry.snapshot.openProposalCount),
            in: 0 ... max(Double(entry.snapshot.totalJobs), 1)
        ) {
            Image(systemName: "doc.text.fill")
        } currentValueLabel: {
            Text("\(entry.snapshot.openProposalCount)")
                .font(.system(.title3, design: .rounded).bold())
        }
        .gaugeStyle(.accessoryCircular)
    }
}

// MARK: - Lock Screen (Rectangular)

struct ProposalsRectangularView: View {
    let entry: ProposalsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption2)
                Text("MMCC")
                    .font(.caption2.weight(.bold))
            }
            HStack(spacing: 8) {
                Label("\(entry.snapshot.openProposalCount) open", systemImage: "doc.text.fill")
                    .font(.caption.weight(.semibold))
                if entry.snapshot.overdueCount > 0 {
                    Label("\(entry.snapshot.overdueCount) overdue", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                }
            }
            Text(entry.snapshot.unpaidTotal + " unpaid")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Widget Configuration

struct MMCCProposalsWidget: Widget {
    let kind = "MMCCProposalsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProposalsProvider()) { entry in
            ProposalsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("MMCC Proposals")
        .description("Open proposal count and unpaid totals for your Lock Screen.")
        .supportedFamilies([
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular,
        ])
    }
}

struct ProposalsWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: ProposalsEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            ProposalsInlineView(entry: entry)
        case .accessoryCircular:
            ProposalsCircularView(entry: entry)
        case .accessoryRectangular:
            ProposalsRectangularView(entry: entry)
        default:
            ProposalsInlineView(entry: entry)
        }
    }
}
