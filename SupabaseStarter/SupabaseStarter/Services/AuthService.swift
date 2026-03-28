import Foundation
import Auth

enum AuthError: LocalizedError {
    case signInFailed(String)
    case signUpFailed(String)
    case signOutFailed(String)
    case oauthFailed(String)
    case noSession

    var errorDescription: String? {
        switch self {
        case .signInFailed(let msg): "Sign in failed: \(msg)"
        case .signUpFailed(let msg): "Sign up failed: \(msg)"
        case .signOutFailed(let msg): "Sign out failed: \(msg)"
        case .oauthFailed(let msg): "OAuth failed: \(msg)"
        case .noSession: "No active session"
        }
    }
}

struct AuthService {

    // MARK: - Email Auth

    func signIn(email: String, password: String) async throws -> Session {
        do {
            return try await supabase.auth.signIn(email: email, password: password)
        } catch {
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }

    func signUp(email: String, password: String) async throws -> Session {
        do {
            let response = try await supabase.auth.signUp(email: email, password: password)
            guard let session = response.session else {
                throw AuthError.signUpFailed("Email confirmation may be required.")
            }
            return session
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.signUpFailed(error.localizedDescription)
        }
    }

    // MARK: - OAuth

    func signInWithApple() async throws {
        do {
            try await supabase.auth.signInWithOAuth(.apple, redirectTo: SupabaseConfig.redirectURL)
        } catch {
            throw AuthError.oauthFailed(error.localizedDescription)
        }
    }

    func signInWithGoogle() async throws {
        do {
            try await supabase.auth.signInWithOAuth(.google, redirectTo: SupabaseConfig.redirectURL)
        } catch {
            throw AuthError.oauthFailed(error.localizedDescription)
        }
    }

    // MARK: - Session

    func currentSession() async throws -> Session {
        do {
            return try await supabase.auth.session
        } catch {
            throw AuthError.noSession
        }
    }

    func signOut() async throws {
        do {
            try await supabase.auth.signOut()
        } catch {
            throw AuthError.signOutFailed(error.localizedDescription)
        }
    }
}
