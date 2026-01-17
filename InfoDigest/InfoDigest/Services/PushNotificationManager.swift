import Foundation
import UserNotifications
import UIKit
import Combine

/// 推送通知管理器
class PushNotificationManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var deviceToken: String?

    var cancellables = Set<AnyCancellable>()
    private let apiService = APIService.shared

    /// 请求推送通知权限
    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if let error = error {
                    print("推送授权失败: \(error.localizedDescription)")
                }
            }
        }

        // 设置代理
        center.delegate = self

        // 注册远程通知
        UIApplication.shared.registerForRemoteNotifications()
    }

    /// 处理device token
    func handleDeviceTokenRegistration(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token
        print("Device Token: \(token)")

        // 发送token到服务器
        Task {
            do {
                try await apiService.registerDevice(token: token)
                print("Device token注册成功")
            } catch {
                print("Device token注册失败: \(error)")
            }
        }
    }

    /// 处理device token注册失败
    func handleDeviceTokenRegistrationFailure(_ error: Error) {
        print("Device Token注册失败: \(error.localizedDescription)")
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension PushNotificationManager: UNUserNotificationCenterDelegate {
    /// 前台时显示通知
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    /// 用户点击通知时的处理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // 处理通知点击事件，例如导航到特定消息详情
        if let messageIdString = userInfo["messageId"] as? String,
           let messageId = UUID(uuidString: messageIdString) {
            print("用户点击了消息: \(messageId)")
            // 这里可以发送通知来导航到消息详情页
        }

        completionHandler()
    }
}
