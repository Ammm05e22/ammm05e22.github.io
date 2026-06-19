import SwiftUI

struct EntryDetailSheet: View {
    let item: FeedItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(item.headline)
                        .font(.title3.weight(.semibold))
                    Text(DateHelpers.relativeShort(item.entry.occurredAt))
                        .font(.caption.weight(.medium))
                        .tracking(0.6)
                        .foregroundStyle(.secondary)

                    Text(item.entry.rawText)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))

                    if let payload = item.analysis?.payload {
                        section(title: "Facts", items: payload.facts)
                        section(title: "Emotions", items: payload.emotions)
                        section(title: "Assumptions", items: payload.assumptions)
                        if !payload.redFlags.isEmpty {
                            section(title: "Red flags", items: payload.redFlags, color: .red)
                        }
                        if !payload.greenFlags.isEmpty {
                            section(title: "Green flags", items: payload.greenFlags, color: .green)
                        }
                        if let reco = payload.recommendation, !reco.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Recommendation")
                                    .font(.caption.weight(.semibold))
                                    .tracking(0.6)
                                    .foregroundStyle(.secondary)
                                Text(reco)
                                    .font(.callout)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.cyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                            )
                        }
                    } else {
                        Text("Analysis pending or unavailable.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(22)
            }
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func section(title: String, items: [String], color: Color = .primary) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(.caption2.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
                ForEach(items, id: \.self) { line in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•").foregroundStyle(color)
                        Text(line).font(.callout)
                    }
                }
            }
        }
    }
}
