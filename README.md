# InfoDigest - 智能信息推送应用

完整的iOS推送应用解决方案，包含客户端和服务器端。每小时自动获取新闻和股票行情，经LLM分析处理后推送到用户设备。

## 项目结构

```
InfoDigest/
├── InfoDigest/              # iOS客户端
│   ├── InfoDigest/
│   │   ├── Models/          # 数据模型
│   │   ├── Views/           # SwiftUI视图
│   │   ├── ViewModels/      # MVVM架构
│   │   ├── Services/        # API和推送服务
│   │   └── Resources/
│   └── README.md            # iOS文档
│
└── server/                  # Node.js服务器
    ├── src/
    │   ├── config/          # 配置文件
    │   ├── routes/          # API路由
    │   ├── services/        # 业务逻辑
    │   ├── models/          # 数据模型
    │   ├── middleware/      # 中间件
    │   └── utils/           # 工具函数
    ├── logs/                # 日志目录
    ├── certs/               # 证书目录
    └── README.md            # 服务器文档
```

## 快速开始

### 前置要求

- **iOS开发**:
  - Xcode 15+
  - iOS 15+ 设备或模拟器
  - Apple Developer账号（用于APNs）

- **服务器**:
  - Node.js 18+
  - PostgreSQL 14+
  - Redis 7+

### 第一步：启动服务器

```bash
# 1. 安装依赖
cd server
npm install

# 2. 配置环境变量
cp .env.example .env
# 编辑 .env 填入API密钥和数据库配置

# 3. 初始化数据库
npm run migrate

# 4. 启动服务器
npm run dev
```

详细说明请查看 [server/README.md](server/README.md)

### 第二步：运行iOS应用

1. 在Xcode中创建新的iOS App项目
2. 将 `InfoDigest/InfoDigest/` 目录下的Swift文件导入
3. 配置Bundle Identifier和签名证书
4. 运行到设备或模拟器

详细说明请查看 [InfoDigest/README.md](InfoDigest/README.md)

## 核心功能

### iOS客户端
- ✅ SwiftUI现代化界面
- ✅ 消息列表（支持按类型筛选）
- ✅ 富文本详情页（Markdown渲染）
- ✅ 图片画廊展示
- ✅ 推送通知处理
- ✅ 设置页面（推送偏好、免打扰）

### 服务器端
- ✅ 定时数据采集（新闻、股票）
- ✅ LLM智能内容生成
- ✅ APNs批量推送
- ✅ PostgreSQL数据持久化
- ✅ RESTful API接口
- ✅ Cron定时任务

## 工作流程

```
1. 定时任务触发（每小时）
   ↓
2. 数据采集
   - NewsAPI: 科技新闻
   - Alpha Vantage: 股票行情
   ↓
3. LLM处理
   - 内容分析
   - 摘要生成
   - Markdown格式化
   ↓
4. 保存到数据库
   ↓
5. APNs推送
   - 查询所有活跃设备
   - 批量发送推送通知
   ↓
6. 用户接收
   - iOS显示推送通知
   - 点击查看完整内容
```

## API接口

### 设备管理
```
POST /api/devices/register     # 注册设备Token
PUT  /api/devices/:id/preferences  # 更新设备偏好
GET  /api/devices/:id          # 获取设备信息
```

### 消息管理
```
GET /api/messages              # 获取消息列表（分页）
GET /api/messages/:id          # 获取消息详情
PUT /api/messages/:id/read     # 标记已读
GET /api/messages/latest/:type # 获取最新消息
```

### 管理接口（开发环境）
```
POST /api/admin/test-push      # 发送测试推送
POST /api/admin/run-digest     # 手动触发摘要生成
```

## 环境变量配置

### 必需配置
```env
# 数据库
DB_HOST=localhost
DB_NAME=infodigest
DB_USER=postgres
DB_PASSWORD=your_password

# API密钥
NEWS_API_KEY=your_newsapi_key
OPENAI_API_KEY=your_openai_key

# APNs推送
APNS_KEY_ID=your_key_id
APNS_TEAM_ID=your_team_id
APNS_BUNDLE_ID=com.yourcompany.InfoDigest
APNS_KEY_PATH=./certs/AuthKey_KEY_ID.p8
```

### 可选配置
```env
# 股票数据（如不需要可留空）
STOCK_API_KEY=

# Redis缓存（如不需要可留空）
REDIS_HOST=localhost
REDIS_PORT=6379

# 定时任务频率
CRON_SCHEDULE=0 * * * *  # 每小时
```

## 部署指南

### 服务器部署

支持的平台：
- [Railway](https://railway.app) - 推荐，零配置
- [Render](https://render.com) - 免费套餐可用
- [Vercel](https://vercel.com) - 仅适用于无服务器部署
- [AWS EC2](https://aws.amazon.com/ec2) - 完全控制
- [Docker](https://docker.com) - 容器化部署

详细步骤请查看 [server/README.md](server/README.md)

### iOS应用部署

1. **发布到App Store**
   - 配置生产环境APNs证书
   - 更新API服务器地址
   - 提交到App Store Connect

2. **TestFlight测试**
   - 添加测试员
   - 分发测试版本

3. **Ad Hoc分发**
   - 导出IPA文件
   - 分发给特定设备

## 数据源

### 新闻数据
- [NewsAPI.org](https://newsapi.org) - 每日100次免费请求

### 股票数据
- [Alpha Vantage](https://www.alphavantage.co) - 每日25次免费请求

### LLM服务
- [OpenAI GPT-4o-mini](https://openai.com) - 最经济实惠
- 可替换为本地模型（Ollama等）

## 故障排查

### 推送不工作
1. 检查APNs证书配置
2. 确认设备Token正确注册
3. 查看服务器日志：`tail -f server/logs/error.log`

### LLM处理失败
服务器会自动降级到简单模式，无需人工干预。

### 数据库连接失败
```bash
# 检查PostgreSQL状态
psql -h localhost -U postgres -c "SELECT version();"
```

## 开发路线图

- [ ] 支持Android客户端
- [ ] 多语言支持
- [ ] 用户账户系统
- [ ] 消息搜索功能
- [ ] 自定义推送频率
- [ ] 更多数据源（天气、加密货币等）
- [ ] Web管理后台

## 贡献

欢迎提交Issue和Pull Request！

## 许可证

MIT License - 自由使用和修改

## 联系方式

如有问题，请提交Issue或联系开发者。
