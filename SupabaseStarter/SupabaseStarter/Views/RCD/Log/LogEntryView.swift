import SwiftUI

struct LogEntryView: View {
    var preselectedPersonId: UUID?
    @State private var viewModel = LogEntryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("New entry")
                        .font(.system(size: 28, weight: .bold))
                        .kerning(-0.4)
                        .padding(.top, 6)

                    if !viewModel.availablePeople.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Person")
                                .font(.caption.weight(.semibold))
                                .tracking(0.6)
                                .foregroundStyle(.secondary)
                            Picker("Person", selection: $viewModel.selectedPersonId) {
                                ForEach(viewModel.availablePeople) { p in
                                    Text(p.displayName).tag(Optional(p.id))
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("What happened?")
                            .font(.caption.weight(.semibold))
                            .tracking(0.6)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $viewModel.rawText)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 160)
                            .padding(10)
                            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("When")
                            .font(.caption.weight(.semibold))
                            .tracking(0.6)
                            .foregroundStyle(.secondary)
                        DatePicker(
                            "Occurred at",
                            selection: $viewModel.occurredAt,
                            in: ...Date()
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task {
                            if await viewModel.submit() {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isSubmitting {
                                ProgressView().tint(.black).scaleEffect(0.85)
                            }
                            Text(viewModel.isSubmitting ? "Analyzing…" : "Log entry")
                                .font(.callout.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSubmitting || viewModel.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .frame(maxWidth: 460)
                .frame(maxWidth: .infinity)
            }
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task { await viewModel.loadPeople(preselect: preselectedPersonId) }
        }
    }
}
