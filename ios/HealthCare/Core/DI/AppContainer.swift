import Foundation

@MainActor
final class AppContainer: ObservableObject {
    let tokenStore: TokenStore
    let apiClient: APIClient
    private let fcmTokenUploader: FcmTokenUploader

    init() {
        let tokenStore = TokenStore()

        let configuredBaseURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
        let environmentBaseURL = ProcessInfo.processInfo.environment["BASE_URL"]
        let baseURLString = environmentBaseURL ?? configuredBaseURL ?? Constants.API.defaultBaseURL

        guard let baseURL = URL(string: baseURLString) else {
            preconditionFailure("Invalid API base URL: \(baseURLString)")
        }

        let apiClient = APIClient(baseURL: baseURL, tokenStore: tokenStore)
        self.tokenStore = tokenStore
        self.apiClient  = apiClient
        self.fcmTokenUploader = FcmTokenUploader(apiClient: apiClient)
    }
}
