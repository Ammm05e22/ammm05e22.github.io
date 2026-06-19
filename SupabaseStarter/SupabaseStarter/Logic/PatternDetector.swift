import Foundation

enum PatternSeverity: String, Sendable {
    case info
    case warn
    case alert
}

struct DetectedPattern: Identifiable, Sendable, Hashable {
    let id = UUID()
    let severity: PatternSeverity
    let text: String

    static func == (lhs: DetectedPattern, rhs: DetectedPattern) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum PatternDetector {

    static func detect(entries: [Entry], analyses: [EntryAnalysis], history: [ScoreHistoryRow]) -> [DetectedPattern] {
        var out: [DetectedPattern] = []

        // 1. Silence streak: gap of 7+ days between consecutive entries
        let sorted = entries.sorted { $0.occurredAt < $1.occurredAt }
        if sorted.count >= 2 {
            for i in 1..<sorted.count {
                let gap = sorted[i].occurredAt.timeIntervalSince(sorted[i-1].occurredAt) / 86400.0
                if gap >= 7 {
                    out.append(DetectedPattern(
                        severity: .warn,
                        text: "Silence streak of \(Int(gap)) days between entries on \(formattedShort(sorted[i-1].occurredAt)) and \(formattedShort(sorted[i].occurredAt))."
                    ))
                    break
                }
            }
        }

        // 2. Repeat red flags across 3+ analyses
        var flagCounts: [String: Int] = [:]
        for a in analyses {
            for f in a.payload.redFlags {
                flagCounts[f.lowercased(), default: 0] += 1
            }
        }
        for (flag, count) in flagCounts where count >= 3 {
            out.append(DetectedPattern(
                severity: .alert,
                text: "Repeat red flag (\(count)×): \(flag)."
            ))
        }

        // 3. 14-day decay on emotional safety or consistency
        let trend = Scoring.trend14d(history: history)
        if trend <= -10 {
            out.append(DetectedPattern(
                severity: .alert,
                text: "Composite dropped \(Int(abs(trend))) points over the last 14 days."
            ))
        } else if trend <= -4 {
            out.append(DetectedPattern(
                severity: .warn,
                text: "Composite drifted down \(Int(abs(trend))) points in 14 days."
            ))
        }

        // 4. Distance-then-warmth pattern (AI-tagged)
        let dtwHits = analyses.filter { $0.payload.patternsDetected.contains(where: { $0.localizedCaseInsensitiveContains("delayed") || $0.localizedCaseInsensitiveContains("overcorrect") }) }
        if dtwHits.count >= 3 {
            out.append(DetectedPattern(
                severity: .warn,
                text: "Distance-then-warmth cycle detected \(dtwHits.count) times in recent entries."
            ))
        }

        return Array(out.prefix(5))
    }

    private static func formattedShort(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }
}
