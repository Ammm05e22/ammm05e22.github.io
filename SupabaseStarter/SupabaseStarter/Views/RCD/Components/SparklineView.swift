import SwiftUI
import Charts

struct SparklineView: View {
    let history: [ScoreHistoryRow]

    var body: some View {
        let sorted = history.sorted { $0.createdAt < $1.createdAt }
        Chart {
            ForEach(sorted) { row in
                LineMark(
                    x: .value("Time", row.createdAt),
                    y: .value("Composite", row.composite)
                )
                .foregroundStyle(trendColor(sorted))
                .interpolationMethod(.monotone)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: yDomain(sorted))
        .frame(height: 36)
    }

    private func yDomain(_ rows: [ScoreHistoryRow]) -> ClosedRange<Double> {
        guard let lo = rows.map(\.composite).min(),
              let hi = rows.map(\.composite).max() else { return 40...60 }
        let pad = max(1, (hi - lo) * 0.2)
        return max(0, lo - pad)...min(100, hi + pad)
    }

    private func trendColor(_ rows: [ScoreHistoryRow]) -> Color {
        guard let first = rows.first?.composite, let last = rows.last?.composite else {
            return .secondary
        }
        return last >= first ? .green : .red
    }
}
