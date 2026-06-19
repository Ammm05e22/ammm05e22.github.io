import SwiftUI

struct NewsFeedRow: View {
    let item: FeedItem

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Circle()
                .fill(bulletColor)
                .frame(width: 6, height: 6)
                .padding(.top, 5)
            Text(item.headline)
                .font(.callout)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            Text(DateHelpers.relativeShort(item.entry.occurredAt))
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private var bulletColor: Color {
        switch item.bulletKind {
        case .green: return .green
        case .red: return .red
        case .neutral: return .secondary
        }
    }
}
