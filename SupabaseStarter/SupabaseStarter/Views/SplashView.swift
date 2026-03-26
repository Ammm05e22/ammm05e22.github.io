import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false

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
                    .blue, .indigo, .purple,
                    .cyan, .blue, .indigo,
                    .teal, .cyan, .blue
                ]
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, options: .repeating)

                Text("Supabase Starter")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.2)
            }
            .padding(48)
            .glassEffect(.regular.interactive, in: .rect(cornerRadius: 32))
        }
    }
}

#Preview {
    SplashView()
}
