import SwiftUI

enum OAuthProvider {
    case apple
    case google

    var label: String {
        switch self {
        case .apple: "Continue with Apple"
        case .google: "Continue with Google"
        }
    }

    var icon: String {
        switch self {
        case .apple: "apple.logo"
        case .google: "globe"
        }
    }
}

struct OAuthButton: View {
    let provider: OAuthProvider
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: provider.icon)
                    .font(.title3)
                Text(provider.label)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: 14))
    }
}

#Preview {
    VStack(spacing: 12) {
        OAuthButton(provider: .apple) {}
        OAuthButton(provider: .google) {}
    }
    .padding()
}
