import SwiftUI

struct StatusPill: View {
    let status: PortfolioStatus

    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.caption2.weight(.semibold))
            .tracking(0.8)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background, in: Capsule())
            .foregroundStyle(foreground)
    }

    private var background: Color {
        switch status {
        case .buy:        return Color.green.opacity(0.16)
        case .hold:       return Color.white.opacity(0.08)
        case .reduce:     return Color.orange.opacity(0.16)
        case .freeze:     return Color.blue.opacity(0.14)
        case .exit:       return Color.red.opacity(0.18)
        case .watchlist:  return Color.white.opacity(0.05)
        }
    }

    private var foreground: Color {
        switch status {
        case .buy:        return .green
        case .hold:       return .white
        case .reduce:     return .orange
        case .freeze:     return .blue
        case .exit:       return .red
        case .watchlist:  return .secondary
        }
    }
}
