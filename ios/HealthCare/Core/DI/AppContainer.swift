import Foundation

@MainActor
final class AppContainer: ObservableObject {
    let tokenStore: TokenStore
    let apiClient: APIClient
    private let fcmTokenUploader: FcmTokenUploader

    init() {
        let tokenStore = TokenStore()

        #if DEBUG
        let defaultBaseURL = "http://localhost:8080"
        #else
        let defaultBaseURL = "https://api.healthcare.app"
        #endif

        let baseURL = URL(
            string: ProcessInfo.processInfo.environment["BASE_URL"] ?? defaultBaseURL
        )!

        let apiClient = APIClient(baseURL: baseURL, tokenStore: tokenStore)
        self.tokenStore = tokenStore
        self.apiClient  = apiClient
        self.fcmTokenUploader = FcmTokenUploader(apiClient: apiClient)
    }
}
