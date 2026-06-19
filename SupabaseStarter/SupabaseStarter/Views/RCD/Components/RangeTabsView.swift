import SwiftUI

struct RangeTabsView: View {
    @Binding var active: ChartRange

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ChartRange.allCases) { r in
                Button {
                    active = r
                } label: {
                    Text(r.rawValue)
                        .font(.caption.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            active == r ? Color.white.opacity(0.10) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                        .foregroundStyle(active == r ? Color.white : Color.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }
}
