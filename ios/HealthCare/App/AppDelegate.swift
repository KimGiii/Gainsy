import GoogleMobileAds
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        } else {
            print("[Firebase] GoogleService-Info.plist not found — skipping configure in dev")
        }
        configurePushNotifications(application)
        GADMobileAds.sharedInstance().start(completionHandler: nil)

        // Cold start: 앱 종료 상태에서 푸시 탭 → launch 시점에 payload 도착.
        // MainTabView가 아직 onReceive 등록 전이므로 PushRouter에 저장해 consume 대기.
        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any],
           let type = userInfo["type"] as? String {
            Task { @MainActor in
                PushRouter.shared.deliver(type: type)
            }
        }
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[APNs] Failed to register: \(error.localizedDescription)")
    }

    private func configurePushNotifications(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        Task {
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge, .sound])
                if granted {
                    await MainActor.run {
                        application.registerForRemoteNotifications()
                    }
                }
            } catch {
                print("[APNs] Permission request failed: \(error)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: @preconcurrency UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    // User tapped the notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let type = userInfo["type"] as? String else { return }
        // 메인 스레드에서 PushRouter에 전달 — SwiftUI 상태 변경 안전성 보장.
        // NotificationCenter publisher는 race condition(.onReceive 등록 전 fire)이 있어
        // PushRouter의 pending queue 방식으로 일원화.
        await MainActor.run {
            PushRouter.shared.deliver(type: type)
        }
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: @preconcurrency MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        NotificationCenter.default.post(name: .fcmTokenRefreshed, object: token)
    }
}

extension Notification.Name {
    static let fcmTokenRefreshed = Notification.Name("fcmTokenRefreshed")
    // pushNotificationTapped는 PushRouter로 대체되어 제거됨 (cold-start race 해결).
}
