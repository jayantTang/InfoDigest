# iOS开发指南

InfoDigest iOS客户端的开发和调试指南。

## 项目概述

InfoDigest 是一个 iOS 推送通知应用，接收并显示由 Node.js 后端服务器提供的 AI 策划内容摘要（新闻、股票市场数据等）。应用使用 SwiftUI 和 MVVM 架构，通过 Apple Push Notification Service (APNs) 接收通知。

**相关文档：**
- 服务器端文档：`[服务器开发指南](./server-development.md)`
- DeepSeek集成：`[DeepSeek集成文档](./deepseek-integration.md)`
- 项目总体文档：根目录的 `README.md`和 `CLAUDE.md`

## 常用命令

### 自动构建（推荐）

```bash
# 自动构建并安装到iPhone
cd InfoDigest
./scripts/build-ios.sh
```

脚本会：
1. 检查服务器状态
2. 使用xcodebuild编译应用
3. 使用ios-deploy安装到iPhone
4. 启动服务器（如果未运行）

### 手动构建

```bash
# 在 Xcode 中打开
open InfoDigest.xcodeproj

# 或使用命令行构建
xcodebuild -project InfoDigest.xcodeproj \
  -scheme InfoDigest \
  -destination 'id=00008120-00012D1A3C80201E' \
  -configuration Debug \
  -allowProvisioningUpdates \
  build
```

### 测试推送

```bash
# 发送测试推送
curl -X POST http://localhost:3000/api/admin/test-push \
  -H "Content-Type: application/json" \
  -H "X-API-Key: dev-admin-key-12345" \
  -d '{"title":"测试","message":"测试消息"}'
```

## 架构

### 整体模式

应用遵循 **MVVM (Model-View-ViewModel)** 架构，使用 SwiftUI：

- **Models（模型）：** 支持 JSON 解码的数据结构
- **Views（视图）：** 使用 @StateObject 管理 ViewModel 的 SwiftUI 视图
- **ViewModels（视图模型）：** 带有 @Published 属性的 @MainActor 类，用于响应式更新
- **Services（服务）：** 用于 API 和推送通知管理的单例服务

### 核心组件

**入口点：**
- `InfoDigestApp.swift` - 应用生命周期，管理作为环境对象的 PushNotificationManager
- `AppDelegate.swift` - 通过 NotificationCenter 处理 APNs 回调和设备 token 注册

**模型层：**
- `Message.swift` - 核心数据模型，包含：
  - MessageType 枚举（新闻 news、股票 stock、简报 digest、其他 unknown），带图标映射
  - Message 结构体，包含 UUID、日期、富文本内容（Markdown）、图片、链接
  - 自定义 CodingKeys 映射服务器字段（`messageType` → `type`）
  - 用于离线开发/预览的示例数据扩展

**视图模型层：**
- `MessageListViewModel.swift` - @MainActor 类，管理：
  - 从 API 或示例数据加载消息（回退模式）
  - 按类型过滤
  - 异步服务器同步的已读状态管理
  - 加载/错误状态

**视图层：**
- `ContentView.swift` - TabView 容器（消息/设置标签页）
- `MessageListView.swift` - 带下拉刷新、类型过滤的消息卡片列表
- `MessageDetailView.swift` - 完整消息渲染，支持 Markdown、图片、链接
- `SettingsView.swift` - 用户偏好设置

**服务层：**
- `APIService.swift` - 单例，包含：
  - 环境自适应的 baseURL（模拟器：localhost，真机：192.168.1.91）
  - 设备 token 注册端点
  - 消息 CRUD 操作，带自定义日期解码（ISO8601 + 回退）
  - 自定义 APIError 类型，带中文本地化
- `PushNotificationManager.swift` - 包含：
  - 授权请求（.alert, .sound, .badge）
  - 设备 token 处理（Data → 十六进制字符串转换）
  - UNUserNotificationCenterDelegate 处理前台/点击事件
  - 基于 Combine 的响应式更新

### 数据流

**应用启动：**
```
InfoDigestApp → PushNotificationManager.requestAuthorization()
→ AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken
→ NotificationCenter 发送 .deviceTokenReceived
→ PushNotificationManager.handleDeviceTokenRegistration()
→ APIService.registerDevice() → 服务器
```

**消息加载：**
```
MessageListView.onAppear → MessageListViewModel.loadMessages()
→ APIService.fetchMessages() → 服务器
→ JSON 解码，自定义日期处理
→ 更新 @Published messages → UI 刷新
```

**错误处理：**
```
API 失败 → catch 块 → useSampleData = true
→ 加载 Message.sampleMessages → 显示"已切换到示例数据"消息
```

**推送通知流程：**
```
APNs → AppDelegate.didReceive response
→ NotificationCenter 发送 .notificationTapped
→ 导航到消息详情（如果存在 messageId）
```

## 配置

### 环境自适应 API 设置

`APIService.swift` 自动选择服务器 baseURL：

```swift
#if targetEnvironment(simulator)
private let baseURL = "http://localhost:3000/api"
#else
private let baseURL = "http://192.168.1.91:3000/api"  // 根据你的网络更新此地址
#endif
```

**真机测试：** 将 IP 地址更新为服务器的局域网地址。

### APNs 配置

**权限配置** (`InfoDigest.entitlements`)：
```xml
<key>aps-environment</key>
<string>development</string>
```

**Bundle Identifier：** `Gaso.InfoDigest`（必须与服务器的 `APNS_BUNDLE_ID` 匹配）

**Team ID：** `J45TT5R9C6`（付费Apple Developer账号）

**签名：** 需要付费 Apple Developer 账户以使用 Push Notifications capability

### 关键配置信息

- **Bundle ID**: Gaso.InfoDigest
- **Team ID**: J45TT5R9C6
- **APNs Key ID**: 4UMWA4C8CJ
- **最低 iOS 版本**: iOS 26.1
- **部署目标**: iPhone（真机）

### 日期解码

应用处理服务器返回的多种日期格式：
1. ISO8601 格式（标准）
2. 微秒精度格式：`yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'`

### JSON 字段映射

服务器返回 `messageType`，应用使用 `type`：
```swift
enum CodingKeys: String, CodingKey {
    case type = "messageType"
    // ...
}
```

## 开发模式

### 离线开发

应用在 `Message.swift` 中包含完整的示例数据。当 API 不可用时：
- `MessageListViewModel` 自动回退到 `Message.sampleMessages`
- 设置 `useSampleData = true` 防止重复失败的请求
- 显示错误消息："无法连接服务器，已切换到示例数据"

### 响应式编程

- SwiftUI 视图使用 `@StateObject` 管理 ViewModel
- ViewModels 使用 `@Published` 属性进行状态变更
- Combine 框架处理基于 NotificationCenter 的事件
- `@MainActor` 注解确保 UI 更新在主线程

### 错误处理

- 自定义 `APIError` 枚举，带中文本地化描述
- 网络失败时优雅降级到示例数据
- 异步已读状态更新（使用 `try?` 的即发即弃）

### 本地化

所有用户界面字符串都是中文：
- "消息"、"设置"
- 错误消息："无效的URL"、"服务器响应错误"
- 通过 `RelativeDateTimeFormatter` 的相对日期格式化

## 测试和调试

### 示例数据预览

所有 SwiftUI 视图都有 Preview 提供者。`Message.swift` 中的示例数据包括：
- 带图片和链接的新闻消息
- 带表格格式的股票消息
- 多个板块的简报消息

### 推送通知测试

模拟器无法接收真实的 APNs 通知。测试方法：
1. 使用真机（必须）
2. 确保服务器的 `APNS_BUNDLE_ID` 与 app bundle identifier 匹配
3. 检查设备 token 已注册到服务器的 `devices` 表
4. 使用服务器的 `/api/admin/test-push` 端点进行手动测试

### 数据库检查

```bash
# 连接数据库
psql -h localhost -U huiminzhang -d infodigest

# 查看设备
SELECT * FROM devices;

# 查看消息
SELECT * FROM messages ORDER BY created_at DESC LIMIT 10;

# 查看推送日志
SELECT * FROM push_logs ORDER BY created_at DESC LIMIT 10;
```

### 常见问题

**"无法连接服务器" 错误：**
- 模拟器：验证服务器在 localhost:3000 运行
- 真机：更新 `baseURL` 的 IP 地址以匹配你的局域网（192.168.1.91）
- 检查服务器正在运行：`curl http://localhost:3000/health`

**未收到推送通知：**
- 验证 APNs entitlements 配置为 development
- 检查设备 token 已注册到服务器数据库
- 确保服务器的 `.p8` 密钥凭据与 Apple Developer 账户匹配
- 查看服务器日志：`tail -f server/logs/combined.log`

**构建签名错误：**
- 确保使用付费 Apple Developer 账号（个人团队不支持Push Notifications）
- 打开 Xcode：`open InfoDigest.xcodeproj`
- 进入 Signing & Capabilities
- 选择正确的 Team (J45TT5R9C6)

**应用无法安装到iPhone：**
- 确保iPhone已信任此电脑
- 使用自动构建脚本：`cd InfoDigest && ./scripts/build-ios.sh`
- 或使用ios-deploy手动安装

## 项目结构

```
InfoDigest/
├── InfoDigestApp.swift          # 应用入口点
├── AppDelegate.swift            # APNs 回调
├── ContentView.swift            # TabView 根视图
├── InfoDigest.entitlements      # APNs 配置 (development)
├── Models/
│   └── Message.swift           # 数据模型 + 示例数据
├── ViewModels/
│   └── MessageListViewModel.swift  # 业务逻辑
├── Views/
│   ├── MessageListView.swift   # 带过滤的消息列表
│   ├── MessageDetailView.swift # 带 Markdown 的消息详情
│   └── SettingsView.swift      # 应用设置
└── Services/
    ├── APIService.swift        # HTTP 客户端
    └── PushNotificationManager.swift  # APNs 处理器
```

## 重要集成点

1. **服务器通信：** 应用期望 Node.js 服务器提供 `/api` 端点：
   - `POST /api/devices/register` - 设备 token 注册
   - `GET /api/messages?page=1&limit=20` - 消息列表
   - `GET /api/messages/:id` - 消息详情
   - `PUT /api/messages/:id/read` - 标记为已读

2. **Bundle Identifier：** 必须与服务器的 `APNS_BUNDLE_ID` 配置匹配（当前为 `Gaso.InfoDigest`）

3. **最低 iOS 版本：** iOS 26.1（在项目设置中配置）

4. **依赖：** 无外部包依赖（仅使用 Apple 框架）

5. **网络要求：** 真机测试时，iPhone和Mac必须在同一局域网

## 快速命令参考

```bash
# 构建并安装
cd InfoDigest && ./scripts/build-ios.sh

# 检查服务器
curl http://localhost:3000/health

# 查看设备注册
psql -h localhost -U huiminzhang -d infodigest -c "SELECT * FROM devices;"

# 查看日志
tail -f server/logs/combined.log

# 发送测试推送
curl -X POST http://localhost:3000/api/admin/test-push \
  -H "Content-Type: application/json" \
  -H "X-API-Key: dev-admin-key-12345" \
  -d '{"title":"测试","message":"测试消息"}'
```
