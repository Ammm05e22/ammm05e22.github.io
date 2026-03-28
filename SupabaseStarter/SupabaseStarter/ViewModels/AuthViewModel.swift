import Foundation
import Auth

enum AuthState: Equatable {
    case loading
    case unauthenticated
    case authenticated
    case needsOnboarding

    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading),
             (.unauthenticated, .unauthenticated),
             (.authenticated, .authenticated),
             (.needsOnboarding, .needsOnboarding):
            return true
        default:
            return false
        }
    }
}

@Observable
@MainActor
final class AuthViewModel {
    var authState: AuthState = .loading
    var errorMessage: String?
    var isLoading = false

    private let authService = AuthService()
    private let profileService = ProfileService()

    init() {
        Task { await checkSession() }
        listenToAuthChanges()
    }

    // MARK: - Session Check

    func checkSession() async {
        authState = .loading
        do {
            let session = try await authService.currentSession()
            await resolvePostAuth(userId: session.user.id)
        } catch {
            authState = .unauthenticated
        }
    }

    // MARK: - Email Auth

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await authService.signIn(email: email, password: password)
            await resolvePostAuth(userId: session.user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await authService.signUp(email: email, password: password)
            await resolvePostAuth(userId: session.user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - OAuth

    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authService.signInWithApple()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authService.signInWithGoogle()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await authService.signOut()
            authState = .unauthenticated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Post-Auth Resolution

    private func resolvePostAuth(userId: UUID) async {
        do {
            let profile = try await profileService.fetchProfile(userId: userId)
            authState = profile != nil ? .authenticated : .needsOnboarding
        } catch {
            authState = .needsOnboarding
        }
    }

    // MARK: - Auth State Listener

    private func listenToAuthChanges() {
        Task {
            for await (event, session) in supabase.auth.authStateChanges {
                guard [.signedIn, .signedOut, .tokenRefreshed].contains(event) else { continue }

                if let session {
                    await resolvePostAuth(userId: session.user.id)
                } else {
                    authState = .unauthenticated
                }
            }
        }
    }

    func completeOnboarding() {
        authState = .authenticated
    }
}
