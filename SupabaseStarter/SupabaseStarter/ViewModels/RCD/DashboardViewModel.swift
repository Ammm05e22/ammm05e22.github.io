import Foundation
import SwiftUI

struct PersonCard: Identifiable, Sendable {
    let person: Person
    let score: ScoreRow?
    let history14d: [ScoreHistoryRow]
    var id: UUID { person.id }
}

@Observable
@MainActor
final class DashboardViewModel {
    var cards: [PersonCard] = []
    var isLoading = false
    var errorMessage: String?

    var showingAdd = false
    var newName = ""
    var newType: String = "romantic"
    var isCreating = false

    private let peopleService = PeopleService()
    private let scoresService = ScoresService()

    func load() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            guard let userId = try? await supabase.auth.session.user.id else {
                errorMessage = "No active session."
                return
            }
            let people = try await peopleService.listActive(userId: userId)
            let ids = people.map(\.id)
            async let scores = scoresService.getMany(personIds: ids)
            async let history = scoresService.historyForMany(personIds: ids, since: Date().addingTimeInterval(-14 * 24 * 3600))
            let (scoreMap, historyMap) = try await (scores, history)

            cards = people.map { p in
                PersonCard(
                    person: p,
                    score: scoreMap[p.id],
                    history14d: historyMap[p.id] ?? []
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createPerson() async -> Person? {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            errorMessage = "Name is required."
            return nil
        }
        isCreating = true
        defer { isCreating = false }
        do {
            guard let userId = try? await supabase.auth.session.user.id else { return nil }
            let person = try await peopleService.create(PersonInsert(
                userId: userId,
                displayName: name,
                relationshipType: newType
            ))
            // Initialize scores row.
            let neutral = AxisVector.neutral
            _ = try await scoresService.upsert(ScoreRowUpsert(
                personId: person.id,
                userId: userId,
                emotionalSafety: neutral.emotionalSafety,
                consistency: neutral.consistency,
                reciprocity: neutral.reciprocity,
                growthAlignment: neutral.growthAlignment,
                integrity: neutral.integrity,
                attraction: neutral.attraction,
                composite: Scoring.composite(neutral),
                status: PortfolioStatus.watchlist.rawValue,
                lastUpdated: Date()
            ))
            newName = ""
            await load()
            return person
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
