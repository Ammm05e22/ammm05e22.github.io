import SwiftUI

struct RootTabView: View {
    @State private var showingLog = false

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Portfolio", systemImage: "chart.line.uptrend.xyaxis") }

            LogEntryLauncher(showing: $showingLog)
                .tabItem { Label("Log", systemImage: "plus.circle.fill") }

            DisciplineView()
                .tabItem { Label("Discipline", systemImage: "lock.shield") }

            RCDSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(.cyan)
        .preferredColorScheme(.dark)
    }
}

private struct LogEntryLauncher: View {
    @Binding var showing: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.cyan)
                Text("Log a new event")
                    .font(.title3.weight(.semibold))
                Text("Pick a person, write what happened.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button {
                    showing = true
                } label: {
                    Label("New entry", systemImage: "square.and.pencil")
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(Color.white, in: Capsule())
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showing) {
            LogEntryView(preselectedPersonId: nil)
        }
    }
}
