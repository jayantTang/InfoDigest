import SwiftUI

struct SettingsView_v1: View {
    @EnvironmentObject var pushNotificationManager: PushNotificationManager
    @AppStorage("pushEnabled") private var pushEnabled = true
    @AppStorage("quietHoursEnabled") private var quietHoursEnabled = false
    @AppStorage("quietHoursStart") private var quietHoursStart = Date()
    @AppStorage("quietHoursEnd") private var quietHoursEnd = Date()

    var body: some View {
        NavigationView {
            Form {
                // 推送设置
                Section("推送通知") {
                    Toggle("启用推送通知", isOn: $pushEnabled)
                        .onChange(of: pushEnabled) { _, newValue in
                            if !newValue {
                                // 用户关闭推送时的处理
                                print("用户关闭了推送通知")
                            }
                        }

                    if pushEnabled {
                        HStack {
                            Image(systemName: pushNotificationManager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(pushNotificationManager.isAuthorized ? .green : .red)
                            Text(pushNotificationManager.isAuthorized ? "已授权" : "未授权")
                        }

                        if let deviceToken = pushNotificationManager.deviceToken {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("设备Token")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(deviceToken)
                                    .font(.caption)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }

                // 免打扰设置
                Section("免打扰时间") {
                    Toggle("启用免打扰", isOn: $quietHoursEnabled)

                    if quietHoursEnabled {
                        DatePicker("开始时间", selection: $quietHoursStart, displayedComponents: .hourAndMinute)
                        DatePicker("结束时间", selection: $quietHoursEnd, displayedComponents: .hourAndMinute)
                    }
                }

                // 内容偏好
                Section("内容偏好") {
                    NavigationLink {
                        ContentPreferencesView()
                    } label: {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text("内容类型偏好")
                        }
                    }
                }

                // 账户信息
                Section("账户") {
                    HStack {
                        Image(systemName: "person.circle")
                        Text("用户ID")
                        Spacer()
                        Text("user_001")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink {
                        AboutView()
                    } label: {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("关于")
                        }
                    }
                }

                // 版本信息
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}

/// 内容偏好设置视图
struct ContentPreferencesView: View {
    @AppStorage("preferNews") private var preferNews = true
    @AppStorage("preferStock") private var preferStock = true
    @AppStorage("preferDigest") private var preferDigest = true

    var body: some View {
        Form {
            Section {
                Toggle("新闻资讯", isOn: $preferNews)
                Toggle("股票行情", isOn: $preferStock)
                Toggle("AI简报", isOn: $preferDigest)
            } header: {
                Text("选择您想接收的内容类型")
            } footer: {
                Text("取消勾选后，将不会收到该类型的推送通知")
            }
        }
        .navigationTitle("内容偏好")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 关于页面
struct AboutView: View {
    var body: some View {
        Form {
            Section {
                VStack(alignment: .center, spacing: 16) {
                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("InfoDigest")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("智能信息摘要推送应用")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }

            Section("功能说明") {
                Text("• 每小时推送精选资讯")
                Text("• AI智能整理与分析")
                Text("• 支持富文本内容展示")
                Text("• 历史消息随时查看")
            }

            Section {
                Link(destination: URL(string: "https://github.com")!) {
                    HStack {
                        Image(systemName: "link")
                        Text("GitHub 项目")
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView_v1()
        .environmentObject(PushNotificationManager())
}
