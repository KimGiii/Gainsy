import Foundation

enum AuthStatus: Equatable {
    case loading
    case authenticated
    case profileSetup
    case unauthenticated
}

extension Notification.Name {
    static let sessionDidExpire = Notification.Name("com.healthcare.sessionDidExpire")
}

@MainActor
final class AuthState: ObservableObject {
    @Published private(set) var status: AuthStatus = .loading

    private let tokenStore: TokenStore

    init(tokenStore: TokenStore = TokenStore()) {
        self.tokenStore = tokenStore
        checkPersistedAuth()
        NotificationCenter.default.addObserver(
            forName: .sessionDidExpire,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.setUnauthenticated()
            }
        }
    }

    func saveAndAuthenticate(tokenResponse: TokenResponse) {
        tokenStore.save(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken
        )
        status = tokenResponse.onboardingCompleted ? .authenticated : .profileSetup
    }

    func completeProfileSetup() {
        status = .authenticated
    }

    func setUnauthenticated() {
        tokenStore.clearTokens()
        status = .unauthenticated
    }

    private func checkPersistedAuth() {
        status = tokenStore.accessToken != nil ? .authenticated : .unauthenticated
    }
}
