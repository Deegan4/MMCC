import SwiftUI
import Charts

// MARK: - Monthly Revenue Bar Chart

/// Shows a 6-month trailing bar chart of paid invoice revenue.
/// Uses the amber brand color with a navy background.
struct RevenueChartView: View {
    let invoices: [Invoice]

    private var monthlyData: [MonthRevenue] {
        let calendar = Calendar.current
        let now = Date.now

        // Build 6 trailing months (including current)
        return (0..<6).reversed().compactMap { offset -> MonthRevenue? in
            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: now) else { return nil }
            let components = calendar.dateComponents([.year, .month], from: monthStart)
            guard let rangeStart = calendar.date(from: components),
                  let rangeEnd = calendar.date(byAdding: .month, value: 1, to: rangeStart) else { return nil }

            // Sum paid invoices whose payments fall in this month
            let revenue = invoices.reduce(Decimal.zero) { total, invoice in
                let monthPayments = (invoice.payments ?? []).filter { payment in
                    payment.date >= rangeStart && payment.date < rangeEnd
                }
                return total + monthPayments.reduce(Decimal.zero) { $0 + $1.amount }
            }

            let label = monthStart.formatted(.dateTime.month(.abbreviated))
            return MonthRevenue(month: label, date: rangeStart, revenue: NSDecimalNumber(decimal: revenue).doubleValue)
        }
    }

    private var totalRevenue: Decimal {
        monthlyData.reduce(Decimal.zero) { $0 + Decimal(floatLiteral: $1.revenue) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader("Revenue (6 Months)", icon: "chart.bar.fill")
                .foregroundStyle(.white.opacity(0.8))

            VStack(alignment: .leading, spacing: 4) {
                Text(totalRevenue.formatted(.currency(code: "USD")))
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .monospacedDigit()

                Text("Total collected")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }

            Chart(monthlyData) { data in
                BarMark(
                    x: .value("Month", data.month),
                    y: .value("Revenue", data.revenue)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.mmccAmber, Color.mmccAmber.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(abbreviatedCurrency(v))
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(.white.opacity(0.1))
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Color.clear)
            }
            .frame(height: 160)
        }
        .padding(16)
        .cardBackground(cornerRadius: 14)
    }

    private func abbreviatedCurrency(_ value: Double) -> String {
        if value >= 1000 {
            return "$\(String(format: "%.0f", value / 1000))K"
        }
        return "$\(String(format: "%.0f", value))"
    }
}

// MARK: - Proposal Win Rate Ring

/// Ring chart showing accepted vs. declined vs. open proposals.
struct ProposalWinRateView: View {
    let proposals: [Proposal]

    private var accepted: Int { proposals.filter { $0.status == .accepted || $0.status == .invoiced }.count }
    private var declined: Int { proposals.filter { $0.status == .declined || $0.status == .expired }.count }
    private var open: Int { proposals.filter { $0.status == .draft || $0.status == .sent }.count }
    private var decided: Int { accepted + declined }

    private var winRate: Double {
        guard decided > 0 else { return 0 }
        return Double(accepted) / Double(decided) * 100
    }

    private var segments: [WinRateSegment] {
        [
            WinRateSegment(label: "Won", count: accepted, color: .statusAccepted),
            WinRateSegment(label: "Lost", count: declined, color: .statusDeclined),
            WinRateSegment(label: "Open", count: open, color: .statusSent),
        ].filter { $0.count > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader("Win Rate", icon: "target")
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 20) {
                // Ring chart
                ZStack {
                    if segments.isEmpty {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 10)
                    } else {
                        Chart(segments) { segment in
                            SectorMark(
                                angle: .value("Count", segment.count),
                                innerRadius: .ratio(0.7),
                                angularInset: 1.5
                            )
                            .foregroundStyle(segment.color)
                            .cornerRadius(3)
                        }
                    }

                    VStack(spacing: 0) {
                        Text("\(String(format: "%.0f", winRate))%")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Text("win")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .frame(width: 90, height: 90)

                // Legend
                VStack(alignment: .leading, spacing: 6) {
                    WinRateLegendRow(color: .statusAccepted, label: "Won", count: accepted)
                    WinRateLegendRow(color: .statusDeclined, label: "Lost", count: declined)
                    WinRateLegendRow(color: .statusSent, label: "Open", count: open)
                }
            }
        }
        .padding(16)
        .cardBackground(cornerRadius: 14)
    }
}

// MARK: - Supporting Types

struct MonthRevenue: Identifiable {
    let id = UUID()
    let month: String
    let date: Date
    let revenue: Double
}

struct WinRateSegment: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
    let color: Color
}

struct WinRateLegendRow: View {
    let color: Color
    let label: String
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text("\(count)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .monospacedDigit()
        }
    }
}
