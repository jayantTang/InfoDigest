# 市场事件连接失败问题 - 修复完成报告

## ✅ 问题已解决

### 问题原因
iOS应用使用了错误的服务器IP地址：
- **错误地址**：`192.168.1.91:3000` (硬编码在代码中)
- **正确地址**：`192.168.1.93:3000` (实际服务器运行地址)

### 修复内容

#### 1. 修改 APIService.swift
**文件**：`InfoDigest/InfoDigest/Services/APIService.swift`

**修改**：将 `baseURL` 的访问修饰符从 `private` 改为 `internal`

```swift
// 修改前：
private let baseURL = "http://192.168.1.93:3000/api"

// 修改后：
internal let baseURL = "http://192.168.1.93:3000/api"
```

**原因**：需要让其他ViewModel能够访问 `baseURL` 属性

#### 2. 修改 OpportunitiesViewModel.swift
**文件**：`InfoDigest/InfoDigest/ViewModels/OpportunitiesViewModel.swift`

**修改了4处硬编码IP地址**：

1. **loadMarketEvents()** (第101行)
   ```swift
   // 修改前：let urlString = "http://192.168.1.91:3000/api/monitoring/events"
   // 修改后：let urlString = "\(apiService.baseURL)/monitoring/events"
   ```

2. **loadStrategyAnalyses()** (第146行)
   ```swift
   // 修改前：let urlString = "http://192.168.1.91:3000/api/analysis/user/\(userId.uuidString)/strategies"
   // 修改后：let urlString = "\(apiService.baseURL)/analysis/user/\(userId.uuidString)/strategies"
   ```

3. **loadFocusAnalyses()** (第171行)
   ```swift
   // 修改前：let urlString = "http://192.168.1.91:3000/api/analysis/user/\(userId.uuidString)/focus"
   // 修改后：let urlString = "\(apiService.baseURL)/analysis/user/\(userId.uuidString)/focus"
   ```

4. **loadAnalysisStats()** (第196行)
   ```swift
   // 修改前：let urlString = "http://192.168.1.91:3000/api/analysis/stats"
   // 修改后：let urlString = "\(apiService.baseURL)/analysis/stats"
   ```

#### 3. 检查其他ViewModel
**检查结果**：✅ 没有发现其他ViewModel有硬编码IP地址问题

---

## 部署验证

### ✅ 编译成功
```
** BUILD SUCCEEDED **
```

### ✅ 部署成功
App已成功安装到iPhone (汤景扬的iPhone)

**安装详情**：
- Bundle ID: `Gaso.InfoDigest`
- 安装路径: `/private/var/containers/Bundle/Application/466FEE6B-9723-49B9-9CD7-9BB5A4655417/`

### ✅ 服务器端点验证

**测试结果**：
- `/api/market-events/stats` - ✅ 正常工作
- `/api/monitoring/events` - ✅ 正常工作，返回了3个事件

---

## 验证步骤

### 在iPhone上验证

请按照以下步骤验证修复：

1. **打开InfoDigest app**
   - 在主屏幕找到并点击InfoDigest图标

2. **进入"投资机会"页面**
   - 点击底部导航栏的"投资机会"

3. **检查是否正常显示**
   - ✅ 应该能看到市场事件列表
   - ✅ 不应再显示"连接失败"错误
   - ✅ 可以切换到"策略分析"和"关注报告"标签

4. **查看事件详情**
   - 市场事件应该显示：
     - 标题
     - 描述
     - 类别（财报、并购、产品等）
     - 重要性分数

---

## 预期显示内容

### 市场事件列表示例

根据服务器数据，应该能看到类似这样的事件：

1. **美联储宣布维持利率不变** (宏观, 85分)
2. **特斯拉Q4交付量超预期** (财报, 82分)
3. **AAPL发布新一代iPhone** (产品, 78分)

---

## 技术细节

### 修改的文件
1. `APIService.swift` - 1处修改
2. `OpportunitiesViewModel.swift` - 4处修改

### 代码改进
- ✅ 统一使用APIService的baseURL
- ✅ 消除硬编码IP地址
- ✅ 易于维护（只需修改APIService一处）
- ✅ 符合iOS开发最佳实践

### 后续维护
如果服务器IP地址需要更改，只需修改 `APIService.swift` 中的 `baseURL` 即可，所有ViewModel会自动使用新地址。

---

## 完成时间
- 修改时间：2026-01-21 00:36
- 编译时间：约30秒
- 部署时间：约2秒

---

## 联系支持
如果仍然遇到问题，请检查：
1. iPhone是否连接到与服务器相同的网络
2. 服务器是否正在运行（端口3000）
3. 查看app中的具体错误消息
