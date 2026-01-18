import SwiftUI
import Combine

@main
struct InfoDigestApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var pushNotificationManager = PushNotificationManager()

    var body: some Scene {
        WindowGroup {
            ContentView_v2()
                .environmentObject(pushNotificationManager)
                .onAppear {
                    pushNotificationManager.requestAuthorization()
                    setupNotificationObservers()
                }
        }
    }

    /// 设置通知观察者
    private func setupNotificationObservers() {
        // 监听device token
        NotificationCenter.default.publisher(for: .deviceTokenReceived)
            .compactMap { $0.userInfo?["deviceToken"] as? Data }
            .sink { deviceToken in
                pushNotificationManager.handleDeviceTokenRegistration(deviceToken)
            }
            .store(in: &pushNotificationManager.cancellables)

        // 监听注册失败
        NotificationCenter.default.publisher(for: .deviceTokenRegistrationFailed)
            .compactMap { $0.userInfo?["error"] as? Error }
            .sink { error in
                pushNotificationManager.handleDeviceTokenRegistrationFailure(error)
            }
            .store(in: &pushNotificationManager.cancellables)
    }
}
