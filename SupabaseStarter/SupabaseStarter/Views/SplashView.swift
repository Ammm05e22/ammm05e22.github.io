import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "bolt.shield.fill")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
                .symbolEffect(.pulse, options: .repeating)

            Text("Supabase Starter")
                .font(.title)
                .fontWeight(.bold)

            ProgressView()
                .progressViewStyle(.circular)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    SplashView()
}
