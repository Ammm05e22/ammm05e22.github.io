import SwiftUI

@main
struct SupabaseStarterApp: App {
    @State private var authViewModel = AuthViewModel()
    @State private var router = Router()

    var body: some Scene {
        WindowGroup {
            Group {
                switch authViewModel.authState {
                case .loading:
                    SplashView()

                case .unauthenticated:
                    NavigationStack(path: $router.path) {
                        LoginView()
                            .navigationDestination(for: Route.self) { route in
                                switch route {
                                case .signUp:
                                    SignUpView()
                                default:
                                    EmptyView()
                                }
                            }
                    }

                case .needsOnboarding:
                    OnboardingView()

                case .authenticated:
                    NavigationStack(path: $router.path) {
                        HomeView()
                            .navigationDestination(for: Route.self) { route in
                                switch route {
                                case .profile:
                                    ProfileView()
                                default:
                                    EmptyView()
                                }
                            }
                    }
                }
            }
            .environment(authViewModel)
            .environment(router)
            .onOpenURL { url in
                // Handle OAuth callback from Supabase
                Task {
                    await supabase.auth.handle(url)
                }
            }
        }
    }
}
