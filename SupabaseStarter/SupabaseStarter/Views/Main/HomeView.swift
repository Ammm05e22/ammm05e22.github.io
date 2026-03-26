import SwiftUI

struct HomeView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(Router.self) private var router

    var body: some View {
        ZStack {
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    .blue.opacity(0.4), .indigo.opacity(0.3), .purple.opacity(0.3),
                    .cyan.opacity(0.2), .blue.opacity(0.2), .indigo.opacity(0.2),
                    .teal.opacity(0.3), .cyan.opacity(0.2), .blue.opacity(0.3)
                ]
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Welcome card
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.green)
                        .symbolEffect(.breathe)

                    Text("Welcome!")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("You're signed in successfully.")
                        .foregroundStyle(.secondary)
                }
                .padding(36)
                .glassEffect(.regular, in: .rect(cornerRadius: 32))
                .padding(.horizontal, 20)

                Spacer()

                // Action buttons
                VStack(spacing: 14) {
                    Button {
                        router.navigate(to: .profile)
                    } label: {
                        Label("View Profile", systemImage: "person.circle.fill")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 16))
                    .tint(.blue)

                    Button(role: .destructive) {
                        Task { await authViewModel.signOut() }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive, in: .rect(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environment(AuthViewModel())
            .environment(Router())
    }
}
