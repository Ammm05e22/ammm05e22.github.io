import SwiftUI

struct RCDSettingsView: View {
    @State private var viewModel = RCDSettingsViewModel()
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("AI Server") {
                    TextField("https://your-server.example.com", text: $viewModel.aiServerUrlDraft)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    Button(viewModel.isSaving ? "Saving…" : "Save AI server URL") {
                        Task { await viewModel.saveAIServerUrl() }
                    }
                    .disabled(viewModel.isSaving)
                }

                Section("Discipline Mode") {
                    Toggle(
                        "Discipline mode",
                        isOn: Binding(
                            get: { viewModel.settings?.disciplineMode ?? false },
                            set: { newValue in Task { await viewModel.toggleDiscipline(newValue) } }
                        )
                    )
                    ForEach(Array((viewModel.settings?.disciplineTriggers ?? []).enumerated()), id: \.offset) { idx, trigger in
                        HStack {
                            Text(trigger)
                            Spacer()
                            Button(role: .destructive) {
                                Task { await viewModel.removeDisciplineTrigger(at: idx) }
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.red)
                        }
                    }
                    HStack {
                        TextField("Add a trigger…", text: $viewModel.newDisciplineTrigger)
                        Button {
                            Task { await viewModel.addDisciplineTrigger() }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(viewModel.newDisciplineTrigger.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section("Non-negotiables") {
                    ForEach(viewModel.boundaries) { boundary in
                        HStack {
                            Text(boundary.text)
                            Spacer()
                            Button(role: .destructive) {
                                Task { await viewModel.deleteBoundary(boundary) }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.red)
                        }
                    }
                    HStack {
                        TextField("Add a non-negotiable…", text: $viewModel.newBoundaryText)
                        Button {
                            Task { await viewModel.addBoundary() }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(viewModel.newBoundaryText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        Task { await authViewModel.signOut() }
                    } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                if let error = viewModel.errorMessage {
                    Section { Text(error).foregroundStyle(.red).font(.footnote) }
                }
            }
            .navigationTitle("Settings")
            .task { await viewModel.load() }
        }
    }
}
