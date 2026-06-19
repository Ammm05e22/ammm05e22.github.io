import Foundation

enum ChartRange: String, CaseIterable, Sendable, Identifiable {
    case d1 = "1D"
    case d5 = "5D"
    case m1 = "1M"
    case m6 = "6M"
    case y1 = "1Y"
    case all = "ALL"

    var id: String { rawValue }

    var windowSeconds: TimeInterval {
        switch self {
        case .d1:  return 24 * 3600
        case .d5:  return 5 * 24 * 3600
        case .m1:  return 30 * 24 * 3600
        case .m6:  return 182 * 24 * 3600
        case .y1:  return 365 * 24 * 3600
        case .all: return .infinity
        }
    }

    var bucketSeconds: TimeInterval {
        switch self {
        case .d1:  return 3600
        case .d5:  return 6 * 3600
        case .m1:  return 24 * 3600
        case .m6:  return 24 * 3600
        case .y1:  return 7 * 24 * 3600
        case .all: return 7 * 24 * 3600
        }
    }
}

enum DateHelpers {

    static func isoWeek(for date: Date = Date(), calendar: Calendar = .current) -> String {
        var cal = calendar
        cal.firstWeekday = 2 // Monday
        cal.minimumDaysInFirstWeek = 4
        let week = cal.component(.weekOfYear, from: date)
        let year = cal.component(.yearForWeekOfYear, from: date)
        return String(format: "%04d-W%02d", year, week)
    }

    static func relativeShort(_ date: Date, now: Date = Date()) -> String {
        let seconds = now.timeIntervalSince(date)
        if seconds < 60 { return "now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        if seconds < 86400 { return "\(Int(seconds / 3600))h ago" }
        if seconds < 86400 * 30 { return "\(Int(seconds / 86400))d ago" }
        if seconds < 86400 * 365 { return "\(Int(seconds / (86400 * 30)))mo ago" }
        return "\(Int(seconds / (86400 * 365)))y ago"
    }

    static func daysSince(_ date: Date, now: Date = Date()) -> Int {
        max(0, Int(now.timeIntervalSince(date) / 86400.0))
    }
}
