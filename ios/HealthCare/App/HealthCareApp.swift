import SwiftUI
import Firebase

@main
struct HealthCareApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var authState: AuthState
    @StateObject private var appContainer = AppContainer()

    init() {
        let tokenStore = TokenStore()
        if ProcessInfo.processInfo.arguments.contains("UI_TEST_RESET_STATE") {
            tokenStore.clearTokens()
        }
        _authState = StateObject(wrappedValue: AuthState(tokenStore: tokenStore))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authState)
                .environmentObject(appContainer)
        }
    }
}
