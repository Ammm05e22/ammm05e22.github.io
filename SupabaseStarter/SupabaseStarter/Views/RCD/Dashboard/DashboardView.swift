import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Portfolio")
                        .font(.system(size: 34, weight: .bold))
                        .kerning(-0.5)
                        .padding(.top, 8)
                    Text("Track each connection like an asset.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 6)

                    if viewModel.cards.isEmpty && !viewModel.isLoading {
                        emptyState
                    } else {
                        ForEach(viewModel.cards) { card in
                            NavigationLink(value: Route.personDetail(id: card.person.id)) {
                                PersonCardView(card: card)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .frame(maxWidth: 460)
                .frame(maxWidth: .infinity)
            }
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .personDetail(let id):
                    PersonDetailView(personId: id)
                case .logEntry(let pid):
                    LogEntryView(preselectedPersonId: pid)
                default:
                    EmptyView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAdd) {
                AddPersonSheet(viewModel: viewModel)
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)
            Text("No assets yet")
                .font(.title3.weight(.semibold))
            Text("Add a person to start tracking interactions.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                viewModel.showingAdd = true
            } label: {
                Label("Add person", systemImage: "plus")
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.08), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
    }
}

struct AddPersonSheet: View {
    @Bindable var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Person") {
                    TextField("Display name (e.g. \"M.\")", text: $viewModel.newName)
                    Picker("Type", selection: $viewModel.newType) {
                        Text("Romantic").tag("romantic")
                        Text("Friend").tag("friend")
                        Text("Family").tag("family")
                        Text("Work").tag("work")
                        Text("Other").tag("other")
                    }
                }
                if let error = viewModel.errorMessage {
                    Section { Text(error).foregroundStyle(.red).font(.footnote) }
                }
            }
            .navigationTitle("Add person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isCreating ? "Adding…" : "Add") {
                        Task {
                            if let _ = await viewModel.createPerson() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isCreating || viewModel.newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
