import Foundation
import SwiftUI

@Observable
@MainActor
final class RCDSettingsViewModel {
    var settings: UserSettings?
    var boundaries: [Boundary] = []

    var aiServerUrlDraft: String = ""
    var newBoundaryText: String = ""
    var newDisciplineTrigger: String = ""

    var isLoading = false
    var isSaving = false
    var errorMessage: String?

    private let settingsService = SettingsService()
    private let boundariesService = BoundariesService()

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            guard let userId = try? await supabase.auth.session.user.id else { return }
            async let s = settingsService.ensure(userId: userId)
            async let b = boundariesService.list(userId: userId)
            let (settings, bounds) = try await (s, b)
            self.settings = settings
            self.boundaries = bounds
            self.aiServerUrlDraft = settings.aiServerUrl ?? ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveAIServerUrl() async {
        guard let settings else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let trimmed = aiServerUrlDraft.trimmingCharacters(in: .whitespaces)
            let updated = try await settingsService.update(
                userId: settings.userId,
                with: UserSettingsUpdate(aiServerUrl: trimmed.isEmpty ? nil : trimmed)
            )
            self.settings = updated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleDiscipline(_ on: Bool) async {
        guard let settings else { return }
        do {
            let updated = try await settingsService.update(
                userId: settings.userId,
                with: UserSettingsUpdate(disciplineMode: on)
            )
            self.settings = updated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addDisciplineTrigger() async {
        guard let settings else { return }
        let trimmed = newDisciplineTrigger.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        do {
            var triggers = settings.disciplineTriggers
            triggers.append(trimmed)
            let updated = try await settingsService.update(
                userId: settings.userId,
                with: UserSettingsUpdate(disciplineTriggers: triggers)
            )
            self.settings = updated
            newDisciplineTrigger = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeDisciplineTrigger(at index: Int) async {
        guard let settings else { return }
        var triggers = settings.disciplineTriggers
        guard triggers.indices.contains(index) else { return }
        triggers.remove(at: index)
        do {
            let updated = try await settingsService.update(
                userId: settings.userId,
                with: UserSettingsUpdate(disciplineTriggers: triggers)
            )
            self.settings = updated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addBoundary() async {
        let trimmed = newBoundaryText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        do {
            guard let userId = try? await supabase.auth.session.user.id else { return }
            let nextOrder = (boundaries.map(\.sortOrder).max() ?? -1) + 1
            let created = try await boundariesService.create(BoundaryInsert(
                userId: userId,
                text: trimmed,
                sortOrder: nextOrder
            ))
            boundaries.append(created)
            newBoundaryText = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteBoundary(_ boundary: Boundary) async {
        do {
            try await boundariesService.delete(boundary.id)
            boundaries.removeAll { $0.id == boundary.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension UserSettingsUpdate {
    init(aiServerUrl: String?) {
        self.disciplineMode = nil
        self.disciplineTriggers = nil
        self.aiServerUrl = aiServerUrl
        self.timezone = nil
    }
    init(disciplineMode: Bool) {
        self.disciplineMode = disciplineMode
        self.disciplineTriggers = nil
        self.aiServerUrl = nil
        self.timezone = nil
    }
    init(disciplineTriggers: [String]) {
        self.disciplineMode = nil
        self.disciplineTriggers = disciplineTriggers
        self.aiServerUrl = nil
        self.timezone = nil
    }
}
