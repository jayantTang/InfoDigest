import UIKit
import UserNotifications

/// AppDelegate - 处理推送通知的回调
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 配置远程通知
        configureRemoteNotifications()

        return true
    }

    /// 配置远程通知
    private func configureRemoteNotifications() {
        UNUserNotificationCenter.current().delegate = self
    }

    /// 成功注册APNs后获取device token
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // 查找环境对象中的PushNotificationManager
        if let windowScene = application.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {

            // 通过通知中心发送token
            NotificationCenter.default.post(
                name: .deviceTokenReceived,
                object: nil,
                userInfo: ["deviceToken": deviceToken]
            )
        }
    }

    /// 注册APNs失败
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("推送注册失败: \(error.localizedDescription)")

        NotificationCenter.default.post(
            name: .deviceTokenRegistrationFailed,
            object: nil,
            userInfo: ["error": error]
        )
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    /// 前台时展示通知
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    /// 用户点击通知
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // 发送通知，让SwiftUI层处理导航
        NotificationCenter.default.post(
            name: .notificationTapped,
            object: nil,
            userInfo: userInfo
        )

        completionHandler()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let deviceTokenReceived = Notification.Name("deviceTokenReceived")
    static let deviceTokenRegistrationFailed = Notification.Name("deviceTokenRegistrationFailed")
    static let notificationTapped = Notification.Name("notificationTapped")
}
