import Foundation
import SwiftUI

struct FeedItem: Identifiable, Sendable {
    let entry: Entry
    let analysis: EntryAnalysis?
    var id: UUID { entry.id }

    var headline: String {
        if let h = analysis?.payload.headline, !h.isEmpty { return h }
        let raw = entry.rawText
        return raw.count > 70 ? String(raw.prefix(67)) + "…" : raw
    }

    var bulletKind: FeedBulletKind {
        guard let d = analysis?.payload.deltas else { return .neutral }
        let sum = d.emotionalSafety + d.consistency + d.reciprocity
              + d.growthAlignment + d.integrity + d.attraction
        if sum > 0 { return .green }
        if sum < 0 { return .red }
        return .neutral
    }
}

enum FeedBulletKind {
    case green, red, neutral
}

@Observable
@MainActor
final class PersonDetailViewModel {
    var person: Person?
    var score: ScoreRow?
    var history: [ScoreHistoryRow] = []
    var feed: [FeedItem] = []
    var patterns: [DetectedPattern] = []
    var weeklySummary: WeeklySummary?
    var settings: UserSettings?
    var boundaries: [Boundary] = []

    var activeRange: ChartRange = .m1
    var isLoading = false
    var isGeneratingSummary = false
    var isUpdatingStance = false
    var errorMessage: String?

    var selectedFeedItem: FeedItem?

    private let peopleService = PeopleService()
    private let entriesService = EntriesService()
    private let analysisService = AnalysisService()
    private let scoresService = ScoresService()
    private let weeklySummariesService = WeeklySummariesService()
    private let settingsService = SettingsService()
    private let boundariesService = BoundariesService()
    private var aiService = AIServerService()

    func load(personId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            guard let userId = try? await supabase.auth.session.user.id else {
                errorMessage = "No active session."
                return
            }
            async let p = peopleService.get(personId)
            async let s = scoresService.get(personId: personId)
            async let h = scoresService.history(personId: personId, limit: 500)
            async let e = entriesService.listForPerson(personId, limit: 30)
            async let ws = weeklySummariesService.latest(personId: personId)
            async let us = settingsService.ensure(userId: userId)
            async let bs = boundariesService.list(userId: userId)

            let (person, score, history, entries, summary, settings, boundaries) = try await (p, s, h, e, ws, us, bs)
            self.person = person
            self.score = score
            self.history = history
            self.weeklySummary = summary
            self.settings = settings
            self.boundaries = boundaries

            let analyses = try await analysisService.latestForEntries(entries.map(\.id))
            self.feed = entries.map { FeedItem(entry: $0, analysis: analyses[$0.id]) }
            self.patterns = PatternDetector.detect(
                entries: entries,
                analyses: feed.compactMap(\.analysis),
                history: history
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setStance(_ stance: Stance) async {
        guard var current = person else { return }
        isUpdatingStance = true
        defer { isUpdatingStance = false }
        do {
            let updated = try await peopleService.update(current.id, with: PersonUpdate(
                displayName: nil,
                relationshipType: nil,
                notes: nil,
                archived: nil,
                userStance: stance.rawValue,
                userStanceUpdatedAt: Date()
            ))
            current = updated
            person = current
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func generateWeeklySummary() async {
        guard let person, !feed.isEmpty else { return }
        isGeneratingSummary = true
        defer { isGeneratingSummary = false }
        do {
            guard let userId = try? await supabase.auth.session.user.id else {
                errorMessage = "No active session."
                return
            }
            aiService.overrideBaseURL = settings?.aiServerUrl.flatMap(URL.init(string:))

            let req = WeeklySummaryRequest(
                personId: person.id,
                isoWeek: DateHelpers.isoWeek(),
                person: .init(displayName: person.displayName, relationshipType: person.relationshipType),
                entries: feed.prefix(14).map { item in
                    WeeklySummaryRequest.EntryWithAnalysis(
                        occurredAt: item.entry.occurredAt,
                        rawText: item.entry.rawText,
                        analysis: item.analysis?.payload
                    )
                },
                scoreHistory: history.suffix(30).map { h in
                    WeeklySummaryRequest.HistoryPoint(
                        createdAt: h.createdAt,
                        composite: h.composite,
                        axes: h.axes
                    )
                }
            )
            let response = try await aiService.weeklySummary(req)
            let saved = try await weeklySummariesService.upsert(WeeklySummaryUpsert(
                userId: userId,
                personId: person.id,
                isoWeek: DateHelpers.isoWeek(),
                payload: response.summary
            ))
            self.weeklySummary = saved
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
