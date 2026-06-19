import SwiftUI

struct KPIRowView: View {
    let axes: AxisVector

    private let defs: [(KeyPath<AxisVector, Double>, String)] = [
        (\.consistency,     "Plan Commitment Rate"),
        (\.integrity,       "Word-Action Alignment"),
        (\.emotionalSafety, "Warmth Sentiment Score"),
    ]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<defs.count, id: \.self) { i in
                let value = max(0, min(100, Int(axes[keyPath: defs[i].0].rounded())))
                VStack(spacing: 4) {
                    Text("\(value)%")
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                    Text(defs[i].1)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 8)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}
