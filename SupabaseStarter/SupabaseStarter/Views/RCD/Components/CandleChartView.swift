import SwiftUI
import Charts

struct Candle: Identifiable, Sendable, Hashable {
    let id = UUID()
    let time: Date
    let open: Double
    let close: Double
    let high: Double
    let low: Double

    var isUp: Bool { close >= open }
}

enum CandleBuilder {
    static func build(history: [ScoreHistoryRow], range: ChartRange) -> [Candle] {
        let cutoff: Date = range.windowSeconds.isFinite
            ? Date().addingTimeInterval(-range.windowSeconds)
            : Date.distantPast
        let filtered = history.filter { $0.createdAt >= cutoff }
                              .sorted { $0.createdAt < $1.createdAt }
        guard !filtered.isEmpty else { return [] }

        let bucket = range.bucketSeconds
        var groups: [TimeInterval: [Double]] = [:]
        for row in filtered {
            let key = floor(row.createdAt.timeIntervalSince1970 / bucket) * bucket
            groups[key, default: []].append(row.composite)
        }
        return groups.keys.sorted().map { key in
            let values = groups[key] ?? []
            return Candle(
                time: Date(timeIntervalSince1970: key),
                open: values.first ?? 0,
                close: values.last ?? 0,
                high: values.max() ?? 0,
                low: values.min() ?? 0
            )
        }
    }
}

struct CandleChartView: View {
    let history: [ScoreHistoryRow]
    let range: ChartRange

    private var candles: [Candle] { CandleBuilder.build(history: history, range: range) }

    private var yRange: ClosedRange<Double> {
        guard let lo = candles.map(\.low).min(),
              let hi = candles.map(\.high).max() else {
            return 40...60
        }
        let pad = max(2, (hi - lo) * 0.1)
        return max(0, lo - pad)...min(100, hi + pad)
    }

    var body: some View {
        Group {
            if candles.isEmpty {
                ZStack {
                    Color.clear
                    Text("No data in this range")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Chart {
                    ForEach(candles) { c in
                        RuleMark(
                            x: .value("Time", c.time),
                            yStart: .value("Low", c.low),
                            yEnd: .value("High", c.high)
                        )
                        .foregroundStyle(c.isUp ? Color.green : Color.red)

                        RectangleMark(
                            x: .value("Time", c.time),
                            yStart: .value("Open", min(c.open, c.close)),
                            yEnd: .value("Close", max(c.open, c.close)),
                            width: .fixed(6)
                        )
                        .foregroundStyle(c.isUp ? Color.green : Color.red)
                    }
                }
                .chartYScale(domain: yRange)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.04))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date, format: .dateTime.month(.abbreviated).day())
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.04))
                    }
                }
            }
        }
        .frame(height: 180)
    }
}
