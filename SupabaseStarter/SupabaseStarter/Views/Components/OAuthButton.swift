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

    var backgroundColor: Color {
        switch self {
        case .apple: .primary
        case .google: .white
        }
    }

    var foregroundColor: Color {
        switch self {
        case .apple: Color(.systemBackground)
        case .google: .black
        }
    }
}

struct OAuthButton: View {
    let provider: OAuthProvider
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: provider.icon)
                    .font(.title3)
                Text(provider.label)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(provider.backgroundColor)
            .foregroundStyle(provider.foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.secondary.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        OAuthButton(provider: .apple) {}
        OAuthButton(provider: .google) {}
    }
    .padding()
}
