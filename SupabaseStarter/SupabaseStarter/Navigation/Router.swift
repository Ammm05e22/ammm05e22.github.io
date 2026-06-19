import SwiftUI

enum Route: Hashable {
    case login
    case signUp
    case onboarding
    case home
    case profile
    case personDetail(id: UUID)
    case logEntry(personId: UUID?)
}

@Observable
final class Router {
    var path = NavigationPath()

    func navigate(to route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
