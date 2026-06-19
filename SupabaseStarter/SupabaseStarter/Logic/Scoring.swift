import Foundation

enum Scoring {
    static let dampingFactor: Double = 0.6

    static let weights: AxisVector = AxisVector(
        emotionalSafety: 0.25,
        consistency: 0.20,
        reciprocity: 0.15,
        growthAlignment: 0.10,
        integrity: 0.20,
        attraction: 0.10
    )

    static func clamp(_ v: Double, _ lo: Double = 0, _ hi: Double = 100) -> Double {
        min(max(v, lo), hi)
    }

    static func applyDeltas(to axes: AxisVector, deltas: AxisDeltas) -> AxisVector {
        AxisVector(
            emotionalSafety: clamp(axes.emotionalSafety + deltas.emotionalSafety * dampingFactor),
            consistency: clamp(axes.consistency + deltas.consistency * dampingFactor),
            reciprocity: clamp(axes.reciprocity + deltas.reciprocity * dampingFactor),
            growthAlignment: clamp(axes.growthAlignment + deltas.growthAlignment * dampingFactor),
            integrity: clamp(axes.integrity + deltas.integrity * dampingFactor),
            attraction: clamp(axes.attraction + deltas.attraction * dampingFactor)
        )
    }

    static func composite(_ axes: AxisVector) -> Double {
        axes.emotionalSafety * weights.emotionalSafety
        + axes.consistency * weights.consistency
        + axes.reciprocity * weights.reciprocity
        + axes.growthAlignment * weights.growthAlignment
        + axes.integrity * weights.integrity
        + axes.attraction * weights.attraction
    }

    static func status(composite: Double, trend14d: Double, entryCount: Int, daysSinceLastEntry: Int) -> PortfolioStatus {
        if entryCount < 3 { return .watchlist }
        if composite < 30 { return .exit }
        if composite < 45 && trend14d <= -10 { return .exit }
        if composite < 50 && trend14d <= -3 { return .reduce }
        if abs(trend14d) < 1 && daysSinceLastEntry >= 21 { return .freeze }
        if composite >= 80 { return .buy }
        if composite >= 70 && trend14d >= 3 { return .buy }
        return .hold
    }

    static func trend14d(history: [ScoreHistoryRow]) -> Double {
        guard !history.isEmpty else { return 0 }
        let cutoff = Date().addingTimeInterval(-14 * 24 * 3600)
        let inRange = history.filter { $0.createdAt >= cutoff }
                             .sorted { $0.createdAt < $1.createdAt }
        guard let first = inRange.first, let last = inRange.last else { return 0 }
        return last.composite - first.composite
    }
}
