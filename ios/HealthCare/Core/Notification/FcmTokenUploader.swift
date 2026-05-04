import Foundation

// Uploads the FCM token to the backend whenever it's refreshed.
// Wired in AppContainer; fires and forgets on token change.
@MainActor
final class FcmTokenUploader {

    private let apiClient: APIClient
    private var observer: NSObjectProtocol?

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        observer = NotificationCenter.default.addObserver(
            forName: .fcmTokenRefreshed,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let token = notification.object as? String else { return }
            Task { @MainActor [weak self] in
                await self?.upload(token: token)
            }
        }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    private func upload(token: String) async {
        struct TokenPayload: Encodable { let fcmToken: String }
        guard let body = try? JSONEncoder().encode(TokenPayload(fcmToken: token)) else { return }
        do {
            try await apiClient.requestVoid(.updateProfile(body: body))
        } catch {
            // Non-critical — silently skip; token will be retried on next app launch
        }
    }
}
