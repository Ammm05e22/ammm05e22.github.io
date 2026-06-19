import SwiftUI

struct PersonDetailView: View {
    let personId: UUID
    @State private var viewModel = PersonDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                metric
                CandleChartView(history: viewModel.history, range: viewModel.activeRange)
                    .padding(.top, 6)
                RangeTabsView(active: Binding(
                    get: { viewModel.activeRange },
                    set: { viewModel.activeRange = $0 }
                ))
                if let score = viewModel.score {
                    KPIRowView(axes: score.axes)
                        .padding(.top, 6)
                }
                newsFeedSection
                if !viewModel.patterns.isEmpty {
                    patternsSection
                }
                portfolioSection
                if let summary = viewModel.weeklySummary {
                    weeklySummaryView(summary: summary)
                }
                actionRow
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
            .frame(maxWidth: 460)
            .frame(maxWidth: .infinity)
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.person?.displayName ?? "")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(item: $viewModel.selectedFeedItem) { item in
            EntryDetailSheet(item: item)
        }
        .task { await viewModel.load(personId: personId) }
        .refreshable { await viewModel.load(personId: personId) }
    }

    @ViewBuilder
    private var header: some View {
        if let person = viewModel.person {
            Text(person.displayName)
                .font(.system(size: 38, weight: .bold))
                .kerning(-0.5)
        }
    }

    private var metric: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Relationship Index")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(formattedComposite)
                    .font(.system(size: 44, weight: .bold))
                    .kerning(-0.5)
                    .monospacedDigit()
                deltaLabel
            }
        }
    }

    private var deltaLabel: some View {
        let (delta, pct) = deltaSince(window: viewModel.activeRange.windowSeconds)
        let up = delta >= 0
        return HStack(spacing: 4) {
            Image(systemName: up ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                .font(.caption)
            Text("\(formatted(abs(delta))) (\(formatted(abs(pct)))%)")
                .font(.subheadline)
                .monospacedDigit()
        }
        .foregroundStyle(up ? Color.green : Color.red)
    }

    private var newsFeedSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("News Feed")
                .font(.title3.weight(.bold))
                .padding(.top, 12)
            if viewModel.feed.isEmpty {
                Text("No entries yet — log the first event.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.feed.prefix(12)) { item in
                    Button {
                        viewModel.selectedFeedItem = item
                    } label: {
                        NewsFeedRow(item: item)
                    }
                    .buttonStyle(.plain)
                    Divider().background(Color.white.opacity(0.06))
                }
            }
        }
    }

    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Patterns")
                .font(.title3.weight(.bold))
                .padding(.top, 12)
            ForEach(viewModel.patterns) { pattern in
                VStack(alignment: .leading, spacing: 4) {
                    Text(pattern.severity.rawValue.uppercased())
                        .font(.caption2.weight(.semibold))
                        .tracking(0.8)
                        .foregroundStyle(severityColor(pattern.severity))
                    Text(pattern.text)
                        .font(.callout)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var portfolioSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Portfolio View")
                .font(.title3.weight(.bold))
                .padding(.top, 12)
            ActionBar(activeStance: stance) { selected in
                Task { await viewModel.setStance(selected) }
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            NavigationLink(value: Route.logEntry(personId: personId)) {
                Label("Log entry", systemImage: "plus.circle.fill")
                    .font(.callout.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            Button {
                Task { await viewModel.generateWeeklySummary() }
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isGeneratingSummary {
                        ProgressView().tint(.white).scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(viewModel.isGeneratingSummary ? "Generating…" : "Weekly summary")
                }
                .font(.callout.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            }
            .disabled(viewModel.isGeneratingSummary || viewModel.feed.isEmpty)
        }
        .padding(.top, 18)
    }

    private func weeklySummaryView(summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weekly summary · \(summary.isoWeek)")
                .font(.caption.weight(.medium))
                .tracking(0.6)
                .foregroundStyle(.secondary)
            Text(summary.payload.headline)
                .font(.callout)
                .foregroundStyle(.primary)
            if !summary.payload.themes.isEmpty {
                HStack(spacing: 6) {
                    ForEach(summary.payload.themes, id: \.self) { theme in
                        Text(theme)
                            .font(.caption2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08), in: Capsule())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if let next = summary.payload.nextCheckIn, !next.isEmpty {
                Text(next)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        .padding(.top, 14)
    }

    // MARK: - Helpers

    private var formattedComposite: String {
        let c = viewModel.score?.composite ?? Scoring.composite(.neutral)
        return formatted(c)
    }

    private func formatted(_ v: Double) -> String {
        String(format: "%.2f", v).replacingOccurrences(of: ".", with: ",")
    }

    private var stance: Stance? {
        guard let raw = viewModel.person?.userStance else { return nil }
        return Stance(rawValue: raw)
    }

    private func deltaSince(window: TimeInterval) -> (Double, Double) {
        let sorted = viewModel.history.sorted { $0.createdAt < $1.createdAt }
        guard !sorted.isEmpty else { return (0, 0) }
        let cutoff: Date = window.isFinite ? Date().addingTimeInterval(-window) : Date.distantPast
        let inRange = sorted.filter { $0.createdAt >= cutoff }
        guard let first = inRange.first?.composite,
              let last = inRange.last?.composite else {
            return (0, 0)
        }
        let delta = last - first
        let pct = first > 0 ? (delta / first) * 100 : 0
        return (delta, pct)
    }

    private func severityColor(_ s: PatternSeverity) -> Color {
        switch s {
        case .alert: return .red
        case .warn:  return .orange
        case .info:  return .secondary
        }
    }
}
