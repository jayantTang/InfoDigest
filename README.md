# InfoDigest - 智能信息推送应用

完整的iOS推送应用解决方案，包含客户端和服务器端。每小时自动获取新闻和股票行情，经DeepSeek AI分析处理后推送到用户设备。

## 项目概述

InfoDigest是一个端到端的智能信息推送系统，能够：
- 📰 自动采集科技新闻和股票行情
- 🤖 使用DeepSeek AI生成智能摘要
- 📱 通过APNs推送到iPhone
- 💾 数据持久化存储

## 项目结构

```
InfoDigest/
├── InfoDigest/              # iOS客户端 (Swift/SwiftUI)
│   ├── InfoDigest/
│   │   ├── Models/          # 数据模型
│   │   │   └── Message.swift
│   │   ├── Views/           # SwiftUI视图
│   │   │   ├── ContentView.swift
│   │   │   ├── MessageListView.swift
│   │   │   ├── MessageDetailView.swift
│   │   │   └── SettingsView.swift
│   │   ├── ViewModels/      # MVVM架构
│   │   │   └── MessageListViewModel.swift
│   │   ├── Services/        # API和推送服务
│   │   │   ├── APIService.swift
│   │   │   └── PushNotificationManager.swift
│   │   ├── AppDelegate.swift
│   │   ├── InfoDigestApp.swift
│   │   └── InfoDigest.entitlements
│   └── InfoDigest.xcodeproj
│
└── server/                  # Node.js服务器
    ├── src/
    │   ├── config/          # 配置文件
    │   │   ├── database.js   # PostgreSQL连接
    │   │   ├── logger.js     # Winston日志
    │   │   └── init.sql      # 数据库schema
    │   ├── routes/          # API路由
    │   │   ├── devices.js    # 设备注册
    │   │   └── messages.js   # 消息管理
    │   ├── services/        # 业务逻辑
    │   │   ├── dataFetcher.js    # 数据采集
    │   │   ├── llmProcessor.js   # LLM处理
    │   │   ├── pushService.js    # APNs推送
    │   │   └── scheduler.js      # 定时任务
    │   ├── middleware/      # 中间件
    │   │   ├── auth.js       # API认证
    │   │   ├── errorHandler.js
    │   │   └── rateLimiter.js
    │   └── index.js         # Express服务器
    ├── certs/               # APNs证书目录
    │   └── AuthKey_4UMWA4C8CJ.p8
    ├── logs/                # 日志目录
    └── package.json

├── scripts/               # 统一脚本目录
│   ├── build-ios.sh       # iOS构建脚本
│   ├── start-server.sh    # 服务器启动脚本
│   ├── stop-server.sh     # 服务器停止脚本
│   ├── test-push.sh       # 推送测试脚本
│   └── ...
└── docs/                  # 统一文档目录
    ├── ios-development.md     # iOS开发指南
    ├── server-development.md  # 服务器开发指南
    └── deepseek-integration.md # DeepSeek集成文档
```

## 📚 详细文档

项目包含完整的技术文档，位于 `docs/` 目录：

- **[iOS开发指南](docs/ios-development.md)** - iOS客户端开发、构建和调试
- **[服务器开发指南](docs/server-development.md)** - Node.js服务器架构、API和部署
- **[DeepSeek集成文档](docs/deepseek-integration.md)** - LLM服务配置和使用

## 快速开始

### 前置要求

- **iOS开发**:
  - Xcode 15+
  - iOS 26.1+ 设备
  - Apple Developer账号（付费）

- **服务器**:
  - Node.js 18+
  - PostgreSQL 14+

### 第一步：启动服务器

```bash
# 1. 进入服务器目录
cd server

# 2. 安装依赖
npm install

# 3. 配置环境变量（已配置，直接使用）
# .env 文件已包含所有必要配置

# 4. 初始化数据库
npm run migrate

# 5. 启动服务器
npm run dev
```

服务器将在 `http://localhost:3000` 启动。

### 第二步：运行iOS应用

#### 方法1：使用自动构建脚本（推荐）

```bash
# 运行自动构建脚本
./scripts/build-ios.sh

# 脚本会：
# 1. 检查服务器状态
# 2. 使用xcodebuild编译应用
# 3. 使用ios-deploy安装到iPhone
# 4. 启动服务器（如果未运行）
```

#### 方法2：使用Xcode

1. 打开 `InfoDigest/InfoDigest.xcodeproj`
2. 选择您的iPhone设备
3. 点击运行按钮（⌘R）

应用会自动：
- 请求推送通知权限
- 获取device token
- 注册到服务器
- 加载历史消息

## 核心功能

### iOS客户端
- ✅ SwiftUI现代化界面
- ✅ 消息列表（支持按类型筛选：新闻、股票、简报）
- ✅ 富文本详情页（Markdown渲染）
- ✅ 图片画廊展示
- ✅ 推送通知处理
- ✅ 设置页面
- ✅ 离线示例数据支持

### 服务器端
- ✅ 定时数据采集（NewsAPI、Alpha Vantage）
- ✅ DeepSeek AI智能内容生成
- ✅ APNs批量推送
- ✅ PostgreSQL数据持久化
- ✅ RESTful API接口
- ✅ Cron定时任务（每小时）
- ✅ API认证和限流
- ✅ 完整的错误处理

## 工作流程

```
每小时触发 (CRON: 0 * * * *)
   ↓
1. 数据采集 (dataFetcher.js)
   - NewsAPI: 科技新闻
   - Alpha Vantage: 股票行情
   ↓
2. LLM处理 (llmProcessor.js)
   - DeepSeek API分析
   - 生成中文摘要
   - Markdown格式化
   ↓
3. 保存到数据库 (PostgreSQL)
   - messages表存储
   - data_sources表记录状态
   ↓
4. APNs推送 (pushService.js)
   - 查询所有活跃iOS设备
   - 批量发送推送通知
   - 记录推送日志
   ↓
5. 用户接收
   - iPhone显示推送通知
   - 点击查看完整内容
   - 应用内浏览历史消息
```

## API接口

### 设备管理
```http
POST /api/devices/register     # 注册设备Token
Content-Type: application/json

{
  "deviceToken": "设备token字符串",
  "platform": "ios",
  "appVersion": "1.0.0",
  "osVersion": "26.1"
}
```

### 消息管理
```http
GET /api/messages?page=1&limit=20           # 获取消息列表
GET /api/messages/:id                        # 获取消息详情
PUT /api/messages/:id/read                   # 标记已读
```

### 管理接口（需要API Key）
```http
POST /api/admin/test-push                    # 发送测试推送
POST /api/admin/run-digest                   # 手动触发摘要生成
```

管理接口需要在请求头中包含：
```http
X-API-Key: dev-admin-key-12345
```

## 当前配置

### iOS应用
- **Bundle ID**: `Gaso.InfoDigest`
- **Team ID**: `J45TT5R9C6`
- **最低版本**: iOS 26.1
- **开发环境**: 本地网络 (192.168.1.91:3000)

### 服务器
- **端口**: 3000
- **数据库**: PostgreSQL (localhost:5432)
- **数据库名**: infodigest
- **用户**: huiminzhang

### APNs配置
- **Key ID**: 4UMWA4C8CJ
- **Team ID**: J45TT5R9C6
- **Bundle ID**: Gaso.InfoDigest
- **环境**: development

### LLM配置
- **提供商**: DeepSeek
- **模型**: deepseek-chat
- **成本**: ¥1/百万tokens (输入), ¥2/百万tokens (输出)

### 数据源
- **NewsAPI**: 科技新闻
- **Alpha Vantage**: 股票行情（可选）

## 环境变量

服务器 `.env` 文件已配置：

```env
# 服务器配置
NODE_ENV=development
PORT=3000

# 数据库
DB_HOST=localhost
DB_PORT=5432
DB_NAME=infodigest
DB_USER=huiminzhang
DB_PASSWORD=

# API密钥
NEWS_API_KEY=cc9e5f521cc64efa8f84079b7a4b6c9d
STOCK_API_KEY=your_stock_api_key

# LLM配置
LLM_PROVIDER=deepseek
LLM_MODEL=deepseek-chat
DEEPSEEK_API_KEY=sk-7b132ad9641e45a088beeb8b6520a0fb

# APNs配置
APNS_KEY_ID=4UMWA4C8CJ
APNS_TEAM_ID=J45TT5R9C6
APNS_BUNDLE_ID=Gaso.InfoDigest
APNS_KEY_PATH=./certs/AuthKey_4UMWA4C8CJ.p8
APNS_PRODUCTION=false

# 安全
JWT_SECRET=your_jwt_secret_change_this
ADMIN_API_KEYS=dev-admin-key-12345,prod-admin-key-67890

# 定时任务
CRON_SCHEDULE=0 * * * *  # 每小时
```

## 测试推送

### 1. 确保服务器运行
```bash
curl http://localhost:3000/health
```

应返回：
```json
{
  "success": true,
  "status": "healthy"
}
```

### 2. 确认设备已注册
```bash
psql -h localhost -U huiminzhang -d infodigest -c "SELECT COUNT(*) FROM devices;"
```

### 3. 发送测试推送
```bash
curl -X POST http://localhost:3000/api/admin/test-push \
  -H "Content-Type: application/json" \
  -H "X-API-Key: dev-admin-key-12345" \
  -d '{"title":"测试推送","message":"这是一条测试消息"}'
```

### 4. 手动触发摘要生成
```bash
curl -X POST http://localhost:3000/api/admin/run-digest \
  -H "X-API-Key: dev-admin-key-12345"
```

## 常用命令

### 服务器管理
```bash
# 启动开发服务器
npm run dev

# 启动生产服务器
npm start

# 初始化数据库
npm run migrate

# 查看日志
tail -f logs/combined.log
tail -f logs/error.log

# 测试API
curl http://localhost:3000/health
```

### iOS构建
```bash
# 自动构建并安装到iPhone
./scripts/build-ios.sh

# 清理构建
rm -rf build/
```

### 数据库
```bash
# 连接数据库
psql -h localhost -U huiminzhang -d infodigest

# 查看所有消息
psql -h localhost -U huiminzhang -d infodigest -c "SELECT * FROM messages ORDER BY created_at DESC LIMIT 10;"

# 查看设备
psql -h localhost -U huiminzhang -d infodigest -c "SELECT * FROM devices;"

# 查看推送日志
psql -h localhost -U huiminzhang -d infodigest -c "SELECT * FROM push_logs ORDER BY created_at DESC LIMIT 10;"
```

## 故障排查

### 推送不工作

1. **检查服务器状态**
   ```bash
   curl http://localhost:3000/health
   ```

2. **检查设备是否注册**
   ```bash
   psql -h localhost -U huiminzhang -d infodigest -c "SELECT COUNT(*) FROM devices;"
   ```

3. **检查推送日志**
   ```bash
   tail -50 logs/combined.log | grep -i push
   ```

4. **测试推送**
   ```bash
   curl -X POST http://localhost:3000/api/admin/test-push \
     -H "Content-Type: application/json" \
     -H "X-API-Key: dev-admin-key-12345" \
     -d '{"title":"测试","message":"测试"}'
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

### LLM处理失败

服务器会自动降级到简单模式，不会中断推送。

查看日志：
```bash
tail -f logs/combined.log | grep -i llm
```

### 数据库连接失败

```bash
# 检查PostgreSQL状态
brew services list | grep postgresql

# 重启PostgreSQL
brew services restart postgresql@14

# 测试连接
psql -h localhost -U huiminzhang -c "SELECT version();"
```

## 开发路线图

- [x] 基础推送功能
- [x] DeepSeek AI集成
- [x] iOS客户端开发
- [x] 自动定时任务
- [x] 完整的错误处理
- [ ] 用户账户系统
- [ ] 消息搜索功能
- [ ] 自定义推送频率
- [ ] 更多数据源（天气、加密货币）
- [ ] Web管理后台
- [ ] Android客户端
- [ ] 多语言支持

## 许可证

MIT License - 自由使用和修改

## 技术支持

如有问题，请：
1. 查看本文档的故障排查部分
2. 查看服务器日志：`tail -f logs/combined.log`
3. 提交Issue到GitHub仓库

## 贡献

欢迎提交Issue和Pull Request！

---

**🎉 恭喜！InfoDigest已完全配置并可正常使用！**
