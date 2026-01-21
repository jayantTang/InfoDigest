# InfoDigest - 智能投资监控与分析平台

**版本**: v2.0
**完整AI驱动的投资监控系统** - 从简单推送应用到全面投资分析平台

## 项目概述

InfoDigest是一个端到端的智能投资监控系统，已完成从v1.0（新闻推送）到v2.0（投资分析平台）的重大升级：

### v2.0 核心功能 ⭐

**🤖 AI驱动分析**
- DeepSeek LLM深度集成，提供智能投资建议
- 策略触发自动生成分析报告
- 市场事件经济影响评估
- 临时关注期总结报告

**📊 实时监控引擎**
- 60秒检查周期的实时监控
- 自定义投资策略触发检测
- 临时关注任务自动管理
- 市场事件重要性评分（0-100）

**📱 全功能iOS客户端**
- 7个功能模块（仪表板、机会、组合、关注、策略、临时关注、监控）
- SwiftUI现代化界面
- MVVM架构设计
- 完整的投资管理功能

**🔌 模块化数据采集**
- 6个数据采集器（价格、加密货币、新闻、技术指标、板块、宏观经济）
- 可插拔架构，易于扩展
- 并行采集优化性能
- 统一协调器管理

### v1.0 兼容功能

- ✅ 每小时智能摘要推送
- ✅ 新闻和股票数据采集
- ✅ APNs推送通知
- ✅ 历史消息浏览

---

## 项目结构

```
InfoDigest/
├── InfoDigest/                    # iOS客户端 (5,216行Swift代码)
│   ├── InfoDigest/
│   │   ├── ViewModels/            # MVVM架构 (8个ViewModel)
│   │   │   ├── DashboardViewModel.swift
│   │   │   ├── OpportunitiesViewModel.swift
│   │   │   ├── PortfolioViewModel.swift
│   │   │   ├── WatchlistViewModel.swift
│   │   │   ├── StrategiesViewModel.swift
│   │   │   ├── TemporaryFocusViewModel.swift
│   │   │   ├── MonitoringViewModel.swift
│   │   │   └── MessageListViewModel.swift
│   │   ├── Views/                 # SwiftUI视图 (11个)
│   │   │   ├── DashboardView.swift
│   │   │   ├── OpportunitiesView.swift
│   │   │   ├── PortfolioView.swift
│   │   │   ├── WatchlistView.swift
│   │   │   ├── StrategiesView.swift
│   │   │   ├── TemporaryFocusView.swift
│   │   │   ├── MonitoringView.swift
│   │   │   ├── MarketEventDetailView.swift  # LLM分析展示
│   │   │   ├── MessageListView.swift
│   │   │   ├── MessageDetailView.swift
│   │   │   ├── SettingsView_v1.swift
│   │   │   └── Components/        # 可复用组件
│   │   ├── Models/                # 数据模型
│   │   ├── Services/              # API和推送服务
│   │   │   ├── APIService.swift
│   │   │   └── PushNotificationManager.swift
│   │   ├── ContentView.swift      # 主界面导航
│   │   ├── InfoDigestApp.swift    # 应用入口
│   │   └── AppDelegate.swift      # APNs回调
│   └── InfoDigest.xcodeproj/
│
├── server/                        # Node.js服务器 (13,199行JavaScript代码)
│   ├── src/
│   │   ├── index.js               # Express服务器入口
│   │   ├── config/
│   │   │   ├── database.js        # PostgreSQL连接池
│   │   │   ├── logger.js          # Winston日志
│   │   │   └── migrations/        # 数据库迁移文件
│   │   │       ├── 001_initial_schema_v2.sql
│   │   │       └── 002_upgrade_v1_to_v2.sql
│   │   ├── routes/                # API路由 (10个文件，72个端点)
│   │   │   ├── users.js           # 用户管理 (v2.0)
│   │   │   ├── portfolios.js      # 投资组合 (v2.0)
│   │   │   ├── watchlists.js      # 关注列表 (v2.0)
│   │   │   ├── strategies.js      # 策略管理 (v2.0)
│   │   │   ├── temporaryFocus.js  # 临时关注 (v2.0)
│   │   │   ├── dataCollection.js  # 数据采集控制 (v2.0)
│   │   │   ├── monitoring.js      # 监控引擎 (v2.0)
│   │   │   ├── analysis.js        # LLM分析 (v2.0)
│   │   │   ├── marketEvents.js    # 市场事件 (v2.0)
│   │   │   ├── devices.js         # 设备管理 (v1+v2)
│   │   │   └── messages.js        # 消息管理 (v1.0)
│   │   ├── services/              # 业务服务 (13个)
│   │   │   ├── monitoringEngine.js          # 监控引擎核心 (v2.0)
│   │   │   ├── llmAnalysisService.js        # LLM分析服务 (v2.0)
│   │   │   ├── eventScoringEngine.js        # 事件评分引擎 (v2.0)
│   │   │   ├── pushNotificationQueue.js    # 推送队列管理 (v2.0)
│   │   │   ├── dataCollector.js             # 数据采集协调器 (v2.0)
│   │   │   ├── marketEventsScheduler.js    # 市场事件调度器 (v2.0)
│   │   │   ├── strategyService.js          # 策略业务逻辑 (v2.0)
│   │   │   ├── portfolioService.js         # 组合业务逻辑 (v2.0)
│   │   │   ├── watchlistService.js         # 关注列表逻辑 (v2.0)
│   │   │   ├── temporaryFocusService.js    # 临时关注逻辑 (v2.0)
│   │   │   ├── userService.js              # 用户管理逻辑 (v2.0)
│   │   │   ├── dataFetcher.js              # 数据采集 (v1.0)
│   │   │   ├── llmProcessor.js             # LLM内容生成 (v1.0)
│   │   │   ├── pushService.js              # APNs推送服务
│   │   │   └── scheduler.js                # 定时任务 (v1.0)
│   │   ├── services/collectors/    # 数据采集器 (6个)
│   │   │   ├── baseCollector.js
│   │   │   ├── priceCollector.js           # Alpha Vantage股价
│   │   │   ├── cryptoCollector.js          # CoinGecko加密货币
│   │   │   ├── newsCollector.js            # NewsAPI新闻
│   │   │   ├── technicalIndicatorCollector.js  # 技术指标
│   │   │   ├── sectorCollector.js          # 板块数据
│   │   │   └── macroCollector.js           # 宏观经济
│   │   ├── middleware/            # 中间件
│   │   │   ├── auth.js            # API Key认证
│   │   │   ├── errorHandler.js   # 错误处理
│   │   │   ├── rateLimiter.js    # 速率限制
│   │   │   └── responseFormatter.js
│   │   └── utils/                 # 工具函数
│   ├── logs/                      # 日志目录
│   ├── certs/                     # APNs证书
│   │   └── AuthKey_4UMWA4C8CJ.p8
│   ├── scripts/                   # 测试和管理脚本 (17个)
│   │   ├── test-v2-api.sh
│   │   ├── test-llm-analysis.sh
│   │   ├── test-monitoring.sh
│   │   └── ...
│   └── package.json
│
└── docs/                          # 完整技术文档 (13个)
    ├── ARCHITECTURE_V2.md         # v2.0架构设计
    ├── DATABASE_SCHEMA_V2.md      # v2.0数据库schema
    ├── API_DESIGN.md              # API设计文档
    ├── PHASE1-4_COMPLETION.md     # Phase 1-4完成报告
    ├── IOS_DEVELOPMENT.md         # iOS开发指南
    └── ...
```

---

## 快速开始

### 前置要求

**iOS开发**:
- Xcode 15+
- iOS 26.1+ 设备或模拟器
- Apple Developer账号

**服务器**:
- Node.js 18+
- PostgreSQL 14+
- DeepSeek API Key

### 第一步：启动服务器

```bash
# 1. 进入服务器目录
cd server

# 2. 安装依赖
npm install

# 3. 配置环境变量（.env文件已配置）
# 查看现有配置
cat .env

# 4. 初始化数据库（v2.0 schema）
npm run migrate

# 5. 启动服务器
npm run dev
```

服务器将在 `http://localhost:3000` 启动。

**验证服务器状态**:
```bash
curl http://localhost:3000/health
```

应返回：
```json
{
  "success": true,
  "status": "healthy",
  "timestamp": "2026-01-21T..."
}
```

### 第二步：运行iOS应用

#### 方法1：使用自动构建脚本（推荐）

```bash
# 确保在项目根目录
# 运行自动构建脚本
cd InfoDigest && ./scripts/build-ios.sh
```

脚本会自动：
1. 检查服务器状态
2. 使用xcodebuild编译应用
3. 使用ios-deploy安装到iPhone
4. 验证应用功能

#### 方法2：使用Xcode

1. 打开 `InfoDigest/InfoDigest.xcodeproj`
2. 选择您的iPhone设备（真机或模拟器）
3. 点击运行按钮（⌘R）

应用首次启动会：
- 请求推送通知权限
- 自动获取device token
- 注册到服务器
- 加载v2.0功能界面

---

## 核心功能详解

### 🤖 AI驱动分析（v2.0核心）

**LLM分析服务** (`llmAnalysisService.js`)

1. **策略触发分析**
   - 市场背景分析
   - 技术指标解读
   - 风险评估（置信度评分）
   - 行动建议

2. **临时关注报告**
   - 监控期总结
   - 关键发现提取
   - 价格走势分析
   - 后续建议

3. **市场事件解读**
   - 事件影响评估
   - 受影响资产识别
   - 市场反应分析
   - 未来展望预测

**LLM配置**:
- **默认提供商**: DeepSeek (`deepseek-chat`模型)
- **备用提供商**: OpenAI（通过环境变量切换）
- **智能Fallback**: API失败时自动降级到简单分析

### 📊 实时监控引擎

**监控流程** (每60秒运行一次):

```
监控引擎启动
   ↓
1. 检查投资策略
   - 查询实时价格
   - 评估触发条件
   - 记录触发事件
   ↓
2. 检查临时关注
   - 查询监控目标
   - 检查过期时间
   - 自动清理已过期
   ↓
3. 检查市场事件
   - 评估事件重要性（0-100）
   - 匹配用户组合/关注
   - 高分事件（≥80）即时推送
   ↓
4. 生成LLM分析
   - 策略触发 → 生成深度分析
   - 关注到期 → 生成总结报告
   - 高分事件 → 生成影响评估
   ↓
5. 推送通知队列
   - 去重检查
   - 批量推送到APNs
   - 记录推送日志
```

**手动控制**:
```bash
# 查看监控状态
curl http://localhost:3000/api/monitoring/status \
  -H "X-API-Key: dev-admin-key-12345"

# 启动监控
curl -X POST http://localhost:3000/api/monitoring/start \
  -H "X-API-Key: dev-admin-key-12345"

# 停止监控
curl -X POST http://localhost:3000/api/monitoring/stop \
  -H "X-API-Key: dev-admin-key-12345"

# 手动触发一次检查周期
curl -X POST http://localhost:3000/api/monitoring/check-cycle \
  -H "X-API-Key: dev-admin-key-12345"
```

### 📱 iOS客户端模块

#### 1. 仪表板 (DashboardView)
- 投资组合总览（总价值、今日盈亏）
- 关注列表摘要
- 策略触发统计
- 最近活动记录

#### 2. 投资机会 (OpportunitiesView)
- 市场事件列表（带重要性评分）
- 策略分析报告
- 临时关注报告
- LLM经济影响评估（点击事件详情查看）

#### 3. 投资组合 (PortfolioView)
- 持仓管理（添加/删除/更新）
- 实时价格更新
- 盈亏计算
- 资产分布图表

#### 4. 关注列表 (WatchlistView)
- 添加/删除关注
- 价格变动追踪
- 备注功能

#### 5. 策略管理 (StrategiesView)
- 创建自定义策略
- 启用/禁用策略
- 查看策略触发历史
- 配置触发条件（价格、技术指标等）

#### 6. 临时关注 (TemporaryFocusView)
- 短期监控任务
- 设置监控时长
- 自动过期清理

#### 7. 监控状态 (MonitoringView)
- 监控引擎运行状态
- 系统性能指标
- 手动启停控制

### 🔌 数据采集系统

**采集器架构** (v2.0):

```javascript
// dataCollector.js - 统一协调器
dataCollector.registerCollector('prices', priceCollector);
dataCollector.registerCollector('crypto', cryptoCollector);
dataCollector.registerCollector('news', newsCollector);
dataCollector.registerCollector('technical', technicalIndicatorCollector);
dataCollector.registerCollector('sectors', sectorCollector);
dataCollector.registerCollector('macro', macroCollector);

// 并行采集所有数据
await dataCollector.collectAll();
```

**数据源**:
1. **Alpha Vantage** - 股票价格、技术指标
2. **CoinGecko** - 加密货币价格
3. **NewsAPI** - 科技新闻
4. **FRED** - 宏观经济指标
5. **自定义计算** - 板块性能、RSI、MACD、布林带

---

## API接口

### v2.0 核心端点

#### 用户管理
```http
GET    /api/users/:id                      # 获取用户信息
PUT    /api/users/:id/preferences          # 更新用户偏好
```

#### 投资组合
```http
GET    /api/portfolios?user_id=xxx         # 获取投资组合
POST   /api/portfolios/items               # 添加持仓
PUT    /api/portfolios/items/:id           # 更新持仓
DELETE /api/portfolios/items/:id           # 删除持仓
GET    /api/portfolios/summary?user_id=xxx # 获取组合摘要
```

#### 关注列表
```http
GET    /api/watchlists?user_id=xxx         # 获取关注列表
POST   /api/watchlists/items               # 添加关注
PUT    /api/watchlists/items/:id           # 更新关注
DELETE /api/watchlists/items/:id           # 删除关注
```

#### 策略管理
```http
GET    /api/strategies?user_id=xxx         # 获取策略列表
POST   /api/strategies                     # 创建策略
PUT    /api/strategies/:id                 # 更新策略
PUT    /api/strategies/:id/status          # 更新状态（启用/禁用）
DELETE /api/strategies/:id                 # 删除策略
GET    /api/strategies/:id/triggers        # 获取触发历史
```

#### 临时关注
```http
GET    /api/temporary-focus?user_id=xxx    # 获取临时关注列表
POST   /api/temporary-focus                # 创建临时关注
PUT    /api/temporary-focus/:id            # 更新临时关注
DELETE /api/temporary-focus/:id            # 删除临时关注
GET    /api/temporary-focus/:id/analysis   # 获取分析报告
```

#### 市场事件
```http
GET    /api/market-events                  # 获取市场事件列表
GET    /api/market-events/:id              # 获取事件详情
GET    /api/market-events/:id/analysis     # 获取LLM分析（经济影响评估）
```

#### LLM分析
```http
GET    /api/analysis/stats                 # 获取分析统计
GET    /api/analysis/user/:userId/strategies  # 获取用户策略分析
GET    /api/analysis/user/:userId/focus    # 获取用户关注分析
GET    /api/analysis/strategy/:strategyId  # 获取特定策略分析
POST   /api/analysis/strategy/:id/generate # 手动生成分析（管理员）
```

#### 监控引擎（需要API Key）
```http
GET    /api/monitoring/status              # 获取监控状态
POST   /api/monitoring/start               # 启动监控引擎
POST   /api/monitoring/stop                # 停止监控引擎
POST   /api/monitoring/check-cycle         # 手动触发检查周期
GET    /api/monitoring/metrics             # 获取性能指标
```

#### 数据采集（需要API Key）
```http
POST   /api/data-collection/start          # 启动数据采集
POST   /api/data-collection/stop           # 停止数据采集
GET    /api/data-collection/status         # 获取采集状态
POST   /api/data-collection/collect        # 手动触发采集
```

### v1.0 兼容端点

```http
POST   /api/devices/register               # 注册设备Token
GET    /api/messages                       # 获取消息历史
GET    /api/messages/:id                   # 获取消息详情
PUT    /api/messages/:id/read              # 标记已读
```

### 管理接口（需要API Key）

```http
POST   /api/admin/test-push                # 发送测试推送
POST   /api/admin/run-digest               # 手动触发摘要生成
```

所有管理接口需要在请求头中包含：
```http
X-API-Key: dev-admin-key-12345
```

---

## 环境配置

### 服务器配置 (.env)

**当前配置**:
```env
# 服务器配置
NODE_ENV=development
PORT=3000

# PostgreSQL数据库
DB_HOST=localhost
DB_PORT=5432
DB_NAME=infodigest
DB_USER=huiminzhang
DB_PASSWORD=

# LLM配置（DeepSeek）
LLM_PROVIDER=deepseek
LLM_MODEL=deepseek-chat
DEEPSEEK_API_KEY=sk-7b132ad9641e45a088beeb8b6520a0fb

# 备用LLM（OpenAI，可选）
OPENAI_API_KEY=your_openai_key

# 数据源API密钥
NEWS_API_KEY=cc9e5f521cc64efa8f84079b7a4b6c9d
ALPHA_VANTAGE_API_KEY=demo

# APNs推送配置
APNS_KEY_ID=4UMWA4C8CJ
APNS_TEAM_ID=J45TT5R9C6
APNS_BUNDLE_ID=Gaso.InfoDigest
APNS_KEY_PATH=./certs/AuthKey_4UMWA4C8CJ.p8
APNS_PRODUCTION=false

# 安全配置
JWT_SECRET=your_jwt_secret_change_this
ADMIN_API_KEYS=dev-admin-key-12345

# 定时任务配置
CRON_SCHEDULE=0 * * * *  # 每小时（v1.0）
MONITORING_INTERVAL_MS=60000  # 监控周期60秒（v2.0）
```

### iOS配置

**关键配置** (`InfoDigest/InfoDigest/Services/APIService.swift`):

```swift
// 开发环境（模拟器）
#if targetEnvironment(simulator)
internal let baseURL = "http://localhost:3000/api"
// 开发环境（真机 - 使用你的Mac IP地址）
#else
internal let baseURL = "http://192.168.1.93:3000/api"
#endif

// 生产环境示例
// internal let baseURL = "https://your-server.com/api"
```

**应用配置**:
- **Bundle ID**: `Gaso.InfoDigest`
- **Team ID**: `J45TT5R9C6`
- **最低iOS版本**: iOS 26.1
- **开发环境**: 本地网络 (192.168.1.93:3000)

---

## 数据库架构

### v2.0 数据表（17个）

**用户系统** (3表):
- `users` - 用户账户和偏好设置
- `devices` - iOS设备管理（支持v1和v2）
- `push_logs` - 推送日志

**投资管理** (4表):
- `portfolios` - 投资组合持仓
- `watchlists` - 关注列表
- `strategies` - 投资策略
- `temporary_focus` - 临时关注任务

**市场数据** (6表):
- `prices` - 实时价格数据
- `technical_indicators` - 技术指标（RSI, MACD, 布林带）
- `sector_performance` - 板块表现
- `macro_indicators` - 宏观经济指标
- `crypto_prices` - 加密货币价格
- `news_events` - 市场事件

**分析结果** (3表):
- `strategy_analyses` - 策略分析
- `focus_analyses` - 临时关注报告
- `event_analyses` - 市场事件解读

**v1.0兼容** (1表):
- `messages` - 历史推送消息

### 数据库迁移

**初始化v2.0数据库**:
```bash
cd server
npm run migrate
```

迁移文件会自动：
1. 创建v2.0所有表（如果不存在）
2. 添加必要的索引
3. 设置外键约束

**查看schema详情**:
- 完整schema文档: `docs/DATABASE_SCHEMA_V2.md`
- 迁移文件: `server/src/config/migrations/`

---

## 常用命令

### 服务器管理

```bash
# 启动开发服务器（自动重启）
npm run dev

# 启动生产服务器
npm start

# 初始化数据库
npm run migrate

# 查看日志
tail -f logs/combined.log
tail -f logs/error.log

# 测试API健康
curl http://localhost:3000/health
```

### 监控引擎控制

```bash
# 查看监控状态
curl http://localhost:3000/api/monitoring/status \
  -H "X-API-Key: dev-admin-key-12345"

# 启动监控
curl -X POST http://localhost:3000/api/monitoring/start \
  -H "X-API-Key: dev-admin-key-12345"

# 停止监控
curl -X POST http://localhost:3000/api/monitoring/stop \
  -H "X-API-Key: dev-admin-key-12345"

# 手动触发检查
curl -X POST http://localhost:3000/api/monitoring/check-cycle \
  -H "X-API-Key: dev-admin-key-12345"
```

### 数据库操作

```bash
# 连接数据库
psql -h localhost -U huiminzhang -d infodigest

# 查看所有表
\dt

# 查看用户
psql -h localhost -U huiminzhang -d infodigest \
  -c "SELECT * FROM users;"

# 查看投资组合
psql -h localhost -U huiminzhang -d infodigest \
  -c "SELECT * FROM portfolios ORDER BY created_at DESC LIMIT 10;"

# 查看策略
psql -h localhost -U huiminzhang -d infodigest \
  -c "SELECT * FROM strategies WHERE status='active';"

# 查看市场事件
psql -h localhost -U huiminzhang -d infodigest \
  -c "SELECT * FROM news_events ORDER BY importance_score DESC LIMIT 10;"

# 查看LLM分析
psql -h localhost -U huiminzhang -d infodigest \
  -c "SELECT * FROM event_analyses ORDER BY created_at DESC LIMIT 5;"
```

### iOS构建

```bash
# 自动构建并安装到iPhone
cd InfoDigest && ./scripts/build-ios.sh

# 或手动构建
xcodebuild -workspace InfoDigest.xcworkspace \
  -scheme InfoDigest \
  -configuration Debug \
  -sdk iphoneos \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="iPhone Developer" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# 安装到iPhone
ios-deploy --bundle build/Build/Products/Debug-iphoneos/InfoDigest.app
```

---

## 测试

### 测试脚本（17个）

**位置**: `server/scripts/`

```bash
# v2.0 API完整测试
./test-v2-api.sh

# LLM分析服务测试
./test-llm-analysis.sh

# 监控引擎测试
./test-monitoring.sh

# 数据采集测试
./test-data-collection.sh

# 推送通知测试
./test-push.sh

# 完整用户体验流程
./user-experience-guide.sh

# 一键快速启动
./quickstart.sh
```

### 手动测试推送

```bash
# 发送测试推送
curl -X POST http://localhost:3000/api/admin/test-push \
  -H "Content-Type: application/json" \
  -H "X-API-Key: dev-admin-key-12345" \
  -d '{"title":"测试推送","message":"这是一条测试消息"}'

# 手动触发v1.0摘要生成
curl -X POST http://localhost:3000/api/admin/run-digest \
  -H "X-API-Key: dev-admin-key-12345"
```

---

## 故障排查

### 推送不工作

1. **检查服务器状态**
   ```bash
   curl http://localhost:3000/health
   ```

2. **检查设备注册**
   ```bash
   psql -h localhost -U huiminzhang -d infodigest \
     -c "SELECT COUNT(*) FROM devices;"
   ```

3. **检查推送日志**
   ```bash
   tail -50 logs/combined.log | grep -i push
   ```

4. **测试推送**
   ```bash
   curl -X POST http://localhost:3000/api/admin/test-push \
     -H "X-API-Key: dev-admin-key-12345"
   ```

### iOS应用无法连接服务器

1. **确认服务器运行**
   ```bash
   lsof -i:3000
   ```

2. **检查网络连接**
   - iPhone和Mac在同一局域网
   - 防火墙允许3000端口

3. **更新API地址**
   - 编辑 `InfoDigest/InfoDigest/Services/APIService.swift`
   - 修改 `baseURL` 为正确的IP地址
   - 真机使用Mac的IP地址，模拟器使用localhost

### 监控引擎不工作

1. **检查监控状态**
   ```bash
   curl http://localhost:3000/api/monitoring/status \
     -H "X-API-Key: dev-admin-key-12345"
   ```

2. **查看监控日志**
   ```bash
   tail -f logs/combined.log | grep "Monitoring"
   ```

3. **手动触发检查**
   ```bash
   curl -X POST http://localhost:3000/api/monitoring/check-cycle \
     -H "X-API-Key: dev-admin-key-12345"
   ```

### LLM分析失败

**系统会自动降级到简单模式，不会中断功能。**

查看详细日志：
```bash
tail -f logs/combined.log | grep -i llm
```

检查API密钥：
```bash
# 查看当前LLM配置
grep "LLM_" server/.env

# 测试DeepSeek API
curl https://api.deepseek.com/v1/models \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### 数据库连接失败

```bash
# 检查PostgreSQL状态
brew services list | grep postgresql

# 重启PostgreSQL
brew services restart postgresql@14

# 测试连接
psql -h localhost -U huiminzhang -c "SELECT version();"

# 重新初始化数据库
cd server && npm run migrate
```

---

## 项目文档

### 核心技术文档（13个）

**位置**: `docs/`

| 文档 | 内容 |
|------|------|
| `ARCHITECTURE_V2.md` | v2.0完整架构设计 |
| `DATABASE_SCHEMA_V2.md` | v2.0数据库schema详解 |
| `API_DESIGN.md` | API设计文档 |
| `PHASE1-4_COMPLETION.md` | Phase 1-4完成报告 |
| `IOS_DEVELOPMENT.md` | iOS开发指南 |
| `server-development.md` | 服务器开发指南 |
| `deepseek-integration.md` | DeepSeek集成文档 |
| `FIX_REPORT.md` | Bug修复报告 |
| `DEPLOYMENT_GUIDE.md` | 部署指南 |
| `TESTING_GUIDE.md` | 测试指南 |
| `PERFORMANCE_ANALYSIS.md` | 性能分析 |
| `FUTURE_PLANS.md` | 未来规划 |
| `CHANGELOG.md` | 变更日志 |

### Phase完成报告

- ✅ **Phase 1**: v2.0基础架构、用户配置API
- ✅ **Phase 2**: 数据采集系统（6个采集器）
- ✅ **Phase 3**: 监控引擎、事件评分、市场事件
- ✅ **Phase 4**: LLM分析服务、报告生成
- ✅ **iOS v2.0**: 所有功能界面实现

---

## 开发路线图

### 已完成 ✅

| 功能 | 状态 | 完成日期 |
|------|------|---------|
| v1.0基础推送 | ✅ | 2026-01-14 |
| v2.0架构设计 | ✅ | 2026-01-15 |
| 数据采集系统 | ✅ | 2026-01-16 |
| 监控引擎 | ✅ | 2026-01-18 |
| LLM分析服务 | ✅ | 2026-01-18 |
| iOS v2.0界面 | ✅ | 2026-01-19 |
| 市场事件分析 | ✅ | 2026-01-21 |

### 计划中 📋

**短期**（1-2周）:
- [ ] 实现相关性分析（代码中已有TODO）
- [ ] 添加用户登录/注册功能
- [ ] 实现消息搜索功能
- [ ] 优化推送频率控制
- [ ] 添加自动化测试

**中期**（1-2月）:
- [ ] Web管理后台
- [ ] 自定义推送时间设置
- [ ] 更多数据源（天气、加密货币扩展）
- [ ] 数据导出功能（CSV、Excel）
- [ ] 推送通知历史查询

**长期**（3-6月）:
- [ ] Android客户端
- [ ] 多语言支持（英文、日文）
- [ ] 机器学习推荐系统
- [ ] 社区分享功能
- [ ] 高级图表功能

---

## 项目统计

### 代码规模

- **iOS客户端**: 5,216行Swift代码
  - 8个ViewModels
  - 11个Views
  - 完整MVVM架构

- **服务器端**: 13,199行JavaScript代码
  - 10个路由模块（72个API端点）
  - 13个业务服务
  - 6个数据采集器

### 数据库

- **数据表**: 17个
- **索引**: 35+
- **外键约束**: 12

### API端点

- **v1.0端点**: 4个
- **v2.0端点**: 68个
- **总计**: 72个

### LLM分析

- **策略分析**: 已实现
- **关注报告**: 已实现
- **事件解读**: 已实现
- **置信度评分**: 已实现

---

## 许可证

MIT License - 自由使用和修改

## 技术支持

如有问题，请：
1. 查看本文档的故障排查部分
2. 查看服务器日志：`tail -f logs/combined.log`
3. 查看`docs/`目录下的详细技术文档
4. 提交Issue到GitHub仓库

## 贡献

欢迎提交Issue和Pull Request！

---

**🎉 恭喜！InfoDigest v2.0已完全配置并可正常使用！**

**项目亮点**:
- ✅ 完整的AI驱动投资分析平台
- ✅ 实时监控引擎（60秒周期）
- ✅ 6个数据采集器并行工作
- ✅ LLM深度集成（DeepSeek）
- ✅ 72个API端点，17个数据表
- ✅ 全功能iOS客户端（7个模块）
- ✅ 18,415行代码（iOS + Server）
- ✅ 13个完整技术文档

**下一步建议**:
1. 补充自动化测试
2. 配置生产环境部署
3. 实现用户认证系统
4. 规划Android版本
