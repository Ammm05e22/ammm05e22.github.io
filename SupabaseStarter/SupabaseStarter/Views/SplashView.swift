import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bolt.shield.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("Supabase Starter")
                .font(.title)
                .fontWeight(.bold)

            ProgressView()
                .progressViewStyle(.circular)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    SplashView()
}
