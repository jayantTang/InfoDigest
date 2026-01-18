# InfoDigest iOS v2.0 更新说明

## 更新概述

iOS客户端已成功更新至v2.0版本，完整支持服务器端的智能投资监控系统功能。

## 主要更新内容

### 1. 核心数据模型 (APIService.swift)

新增/更新的数据模型：
- **User**: 用户信息及偏好设置
- **PortfolioItem**: 投资组合持仓
- **WatchlistItem**: 关注列表
- **Strategy**: 监控策略（价格、技术指标、新闻、时间条件）
- **TemporaryFocus**: 临时关注项目
- **MonitoringStatus/Metrics**: 监控状态和指标

### 2. API服务扩展

APIService.swift 现在支持完整的v2.0 API：

#### 用户管理
- `registerDeviceV2()` - 注册设备（返回用户ID）
- `getUser()` - 获取用户信息
- `updateUserPreferences()` - 更新用户偏好

#### 投资组合管理
- `getPortfolio()` - 获取投资组合列表
- `addPortfolioItem()` - 添加持仓
- `deletePortfolioItem()` - 删除持仓

#### 关注列表管理
- `getWatchlist()` - 获取关注列表
- `addWatchlistItem()` - 添加关注
- `deleteWatchlistItem()` - 删除关注

#### 策略管理
- `getStrategies()` - 获取策略列表
- `createStrategy()` - 创建策略
- `updateStrategyStatus()` - 更新策略状态
- `deleteStrategy()` - 删除策略

#### 临时关注
- `getTemporaryFocus()` - 获取临时关注列表
- `createTemporaryFocus()` - 创建临时关注
- `deleteTemporaryFocus()` - 删除临时关注

#### 监控功能
- `getMonitoringStatus()` - 获取监控状态
- `getMonitoringMetrics()` - 获取监控指标

### 3. 用户界面更新 (ContentView_v2.swift)

新的TabView界面，包含6个主要功能模块：

#### 📊 仪表板 (Dashboard)
- 保留v1.0的消息列表功能
- 显示AI生成的简报和新闻摘要

#### 💼 投资组合 (Portfolio)
- 查看所有持仓
- 添加新持仓（股票代码、数量、成本）
- 查看当前市值和盈亏
- 删除持仓
- 点击查看详情

#### ⭐ 关注列表 (Watchlist)
- 查看关注的股票
- 添加新关注（带备注）
- 查看实时价格和涨跌幅
- 删除关注

#### ⚙️ 策略管理 (Strategies)
- 占位符视图（待实现）
- 预留接口用于创建和管理监控策略

#### 👁️ 临时关注 (Temporary Focus)
- 占位符视图（待实现）
- 预留接口用于短期监控项目

#### 📈 监控状态 (Monitoring)
- 查看监控引擎运行状态
- 查看策略统计信息
- 查看队列通知数量
- 手动触发检查

### 4. 应用配置更新

**InfoDigestApp.swift**:
- 主视图切换为 `ContentView_v2()`
- 保留推送通知管理功能

## 技术细节

### 文件结构
```
InfoDigest/
├── InfoDigestApp.swift          (已更新 - 使用ContentView_v2)
├── ContentView.swift             (保留 - v1.0版本)
├── ContentView_v2.swift          (新增 - v2.0主界面)
├── Models/
│   └── Message.swift             (保留 - v1.0消息模型)
├── Services/
│   ├── APIService.swift          (已更新 - 完整v2.0 API支持)
│   └── PushNotificationManager.swift
├── ViewModels/
│   └── MessageListViewModel.swift
└── Views/
    ├── MessageListView.swift
    ├── MessageDetailView.swift
    └── SettingsView.swift
```

### 类型定义
所有v2.0的数据模型现在定义在 `APIService.swift` 文件顶部，包括：
- Domain Models (User, PortfolioItem, etc.)
- API Response Wrapper (APIResponse<T>)
- Response Data Types (UserData, PortfolioData, etc.)
- v1 Compatibility Types (MessageResponse, etc.)

### 服务器连接
```swift
// 模拟器
private let baseURL = "http://localhost:3000/api"

// 真机
private let baseURL = "http://192.168.1.91:3000/api"
```

## 已解决的问题

1. ✅ 类型重复定义导致的编译错误
2. ✅ 前向引用问题（将Domain Models移到文件顶部）
3. ✅ Section header语法更新
4. ✅ TextField autocapitalization API变更
5. ✅ 删除冗余文件（APIService_v2.swift, UserModels.swift）

## 待实现功能

以下视图目前为占位符，需要完整实现：

1. **策略管理界面**
   - 策略列表显示
   - 创建/编辑策略表单
   - 策略条件配置（价格、技术、新闻、时间）
   - 策略触发历史查看

2. **临时关注界面**
   - 临时关注列表
   - 创建关注表单
   - 关注配置选项
   - 查看监控发现

3. **AI分析查看**
   - 策略分析显示
   - 关注报告显示
   - 事件解读显示

## 使用方法

### 编译运行

1. 在Xcode中打开项目
2. 选择目标设备（模拟器或真机）
3. 点击运行按钮

### 首次使用

1. 应用启动后会自动注册设备
2. 获得 userId（通过设备注册响应）
3. 添加投资组合持仓
4. 创建关注列表
5. 设置监控策略
6. 系统自动监控并发送通知

### 服务器配置

确保服务器正在运行：
```bash
cd server
npm start
```

服务器地址：http://localhost:3000

## 下一步建议

1. 实现完整的策略管理界面
2. 实现临时关注功能界面
3. 添加AI分析展示界面
4. 实现用户设置和偏好管理
5. 添加图表和数据可视化
6. 实现推送通知的详细显示
7. 添加单元测试
8. 优化错误处理和用户提示

## 版本历史

- **v2.0** (2026-01-19): 完整的投资监控系统
  - 投资组合管理
  - 关注列表
  - 策略监控
  - 临时关注
  - 监控状态查看

- **v1.0** (之前): 简单的消息推送应用
  - 接收AI生成的简报
  - 查看消息历史
