import SwiftUI

struct ActionBar: View {
    let activeStance: Stance?
    var onSelect: (Stance) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Stance.allCases, id: \.self) { stance in
                Button {
                    onSelect(stance)
                } label: {
                    Text(stance.rawValue)
                        .font(.callout.weight(.semibold))
                        .tracking(0.4)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(background(for: stance), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderColor(for: stance), lineWidth: stance == activeStance ? 1.5 : 0.5)
                        )
                        .foregroundStyle(foreground(for: stance))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func background(for stance: Stance) -> Color {
        if stance == activeStance {
            switch stance {
            case .buy:  return Color.green.opacity(0.16)
            case .sell: return Color.red.opacity(0.16)
            case .hold: return Color.white.opacity(0.08)
            }
        }
        return Color.white.opacity(0.04)
    }

    private func borderColor(for stance: Stance) -> Color {
        if stance == activeStance {
            return foreground(for: stance)
        }
        return Color.white.opacity(0.10)
    }

    private func foreground(for stance: Stance) -> Color {
        switch stance {
        case .buy:  return .green
        case .sell: return .red
        case .hold: return .white
        }
    }
}
