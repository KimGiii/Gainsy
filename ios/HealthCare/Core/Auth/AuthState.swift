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
    /// 사진 분석 등 프리미엄 전용 기능 게이팅용. /me 호출로 동기화.
    @Published private(set) var isPremium: Bool = false

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
        isPremium = false
        status = .unauthenticated
    }

    /// /me 응답의 isPremium을 캐시. 로그인·앱 시작·구독 변경 시 호출.
    func updatePremiumStatus(_ premium: Bool) {
        self.isPremium = premium
    }

    private func checkPersistedAuth() {
        status = tokenStore.accessToken != nil ? .authenticated : .unauthenticated
    }
}
