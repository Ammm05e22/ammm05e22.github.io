import SwiftUI

struct DisciplineView: View {
    @State private var viewModel = RCDSettingsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Discipline Mode")
                        .font(.system(size: 30, weight: .bold))
                        .kerning(-0.4)
                        .padding(.top, 8)

                    Text("Not decision time. Finish your main task. Then reassess.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))

                    Toggle(
                        "Discipline mode on",
                        isOn: Binding(
                            get: { viewModel.settings?.disciplineMode ?? false },
                            set: { newValue in Task { await viewModel.toggleDiscipline(newValue) } }
                        )
                    )
                    .padding(14)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("My triggers")
                            .font(.callout.weight(.semibold))
                        ForEach(Array((viewModel.settings?.disciplineTriggers ?? []).enumerated()), id: \.offset) { idx, trigger in
                            HStack {
                                Image(systemName: "circle.fill").font(.system(size: 6)).foregroundStyle(.secondary)
                                Text(trigger)
                                Spacer()
                                Button {
                                    Task { await viewModel.removeDisciplineTrigger(at: idx) }
                                } label: {
                                    Image(systemName: "minus.circle").foregroundStyle(.red.opacity(0.8))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 6)
                            Divider().background(Color.white.opacity(0.06))
                        }
                        HStack {
                            TextField("Add a trigger…", text: $viewModel.newDisciplineTrigger)
                                .textFieldStyle(.plain)
                            Button {
                                Task { await viewModel.addDisciplineTrigger() }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                            }
                            .disabled(viewModel.newDisciplineTrigger.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.vertical, 6)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rules of discipline mode")
                            .font(.callout.weight(.semibold))
                        ruleRow("No texting until today's main goal is done.")
                        ruleRow("No emotional decision for 24 hours.")
                        ruleRow("Write facts only.")
                        ruleRow("Review the pattern, not the fantasy.")
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .frame(maxWidth: 460)
                .frame(maxWidth: .infinity)
            }
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .task { await viewModel.load() }
        }
    }

    private func ruleRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.cyan).font(.callout)
            Text(text).font(.callout)
        }
    }
}
