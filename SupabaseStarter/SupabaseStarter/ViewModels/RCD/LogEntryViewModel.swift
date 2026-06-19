import Foundation
import SwiftUI

@Observable
@MainActor
final class LogEntryViewModel {
    var rawText: String = ""
    var occurredAt: Date = Date()
    var availablePeople: [Person] = []
    var selectedPersonId: UUID?

    var isLoadingPeople = false
    var isSubmitting = false
    var errorMessage: String?
    var didSubmitForPersonId: UUID?

    private let peopleService = PeopleService()
    private let entriesService = EntriesService()
    private let analysisService = AnalysisService()
    private let scoresService = ScoresService()
    private let boundariesService = BoundariesService()
    private let settingsService = SettingsService()
    private var aiService = AIServerService()

    func loadPeople(preselect: UUID? = nil) async {
        isLoadingPeople = true
        defer { isLoadingPeople = false }
        do {
            guard let userId = try? await supabase.auth.session.user.id else { return }
            let people = try await peopleService.listActive(userId: userId)
            self.availablePeople = people
            if let preselect, people.contains(where: { $0.id == preselect }) {
                self.selectedPersonId = preselect
            } else {
                self.selectedPersonId = self.selectedPersonId ?? people.first?.id
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submit() async -> Bool {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Write something first."
            return false
        }
        guard let personId = selectedPersonId else {
            errorMessage = "Pick a person."
            return false
        }
        isSubmitting = true
        defer { isSubmitting = false }
        errorMessage = nil

        do {
            guard let userId = try? await supabase.auth.session.user.id else {
                errorMessage = "No active session."
                return false
            }
            let entry = try await entriesService.create(EntryInsert(
                userId: userId,
                personId: personId,
                rawText: trimmed,
                occurredAt: occurredAt
            ))

            // Pull context for analysis.
            async let person = peopleService.get(personId)
            async let score = scoresService.get(personId: personId)
            async let recent = entriesService.listForPerson(personId, limit: 10)
            async let bounds = boundariesService.list(userId: userId)
            async let settings = settingsService.ensure(userId: userId)
            let (p, s, r, b, st) = try await (person, score, recent, bounds, settings)

            let currentAxes = s?.axes ?? .neutral
            aiService.overrideBaseURL = st.aiServerUrl.flatMap(URL.init(string:))

            let req = AnalyzeEntryRequest(
                entryId: entry.id,
                person: .init(
                    id: p.id,
                    displayName: p.displayName,
                    relationshipType: p.relationshipType,
                    currentScores: currentAxes
                ),
                rawText: trimmed,
                occurredAt: occurredAt,
                recentEntries: r.filter { $0.id != entry.id }.prefix(10).map {
                    AnalyzeEntryRequest.RecentEntry(occurredAt: $0.occurredAt, rawText: $0.rawText)
                },
                boundaries: b.map(\.text)
            )

            do {
                let response = try await aiService.analyzeEntry(req)
                _ = try await analysisService.insert(EntryAnalysisInsert(
                    entryId: entry.id,
                    userId: userId,
                    model: response.model,
                    payload: response.analysis
                ))

                // Update cumulative score + append history.
                let updated = Scoring.applyDeltas(to: currentAxes, deltas: response.analysis.deltas)
                let composite = Scoring.composite(updated)
                let history = try await scoresService.history(personId: personId, limit: 500)
                let trend = Scoring.trend14d(history: history)
                let entryCount = r.count + 1
                let daysSince = 0
                let newStatus = Scoring.status(
                    composite: composite,
                    trend14d: trend,
                    entryCount: entryCount,
                    daysSinceLastEntry: daysSince
                )
                _ = try await scoresService.upsert(ScoreRowUpsert(
                    personId: personId,
                    userId: userId,
                    emotionalSafety: updated.emotionalSafety,
                    consistency: updated.consistency,
                    reciprocity: updated.reciprocity,
                    growthAlignment: updated.growthAlignment,
                    integrity: updated.integrity,
                    attraction: updated.attraction,
                    composite: composite,
                    status: newStatus.rawValue,
                    lastUpdated: Date()
                ))
                try await scoresService.appendHistory(ScoreHistoryInsert(
                    personId: personId,
                    userId: userId,
                    composite: composite,
                    axes: updated,
                    entryId: entry.id
                ))
            } catch {
                // Entry saved but analysis failed — surface, keep entry intact.
                errorMessage = "Saved entry but AI analysis failed: \(error.localizedDescription)"
            }

            rawText = ""
            occurredAt = Date()
            didSubmitForPersonId = personId
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
