import SwiftUI

struct PersonCardView: View {
    let card: PersonCard

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.person.displayName)
                        .font(.title3.weight(.bold))
                    if let type = card.person.relationshipType {
                        Text(type.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let status = portfolioStatus {
                    StatusPill(status: status)
                }
            }
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Index")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(composite)
                        .font(.system(size: 28, weight: .bold))
                        .monospacedDigit()
                }
                Spacer()
                SparklineView(history: card.history14d)
                    .frame(width: 100)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var composite: String {
        let v = card.score?.composite ?? 50
        return String(format: "%.2f", v).replacingOccurrences(of: ".", with: ",")
    }

    private var portfolioStatus: PortfolioStatus? {
        guard let raw = card.score?.status else { return .watchlist }
        return PortfolioStatus(rawValue: raw)
    }
}
