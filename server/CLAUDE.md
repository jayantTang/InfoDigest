# 服务器开发指南

InfoDigest Node.js服务器的开发和运维指南。

## 项目概述

InfoDigest服务器负责：
- 📰 从NewsAPI和Alpha Vantage采集数据
- 🤖 使用DeepSeek AI生成智能摘要
- 📱 通过APNs推送到iOS设备
- 💾 PostgreSQL数据持久化
- ⏰ Cron定时任务调度

**相关文档：**
- iOS客户端文档：`InfoDigest/IOS_DEVELOPMENT.md`
- 项目总体文档：根目录的 `README.md`和 `CLAUDE.md`

## 快速开始

### 启动服务器

```bash
cd server
npm run dev
```

服务器将在 `http://localhost:3000` 启动。

### 数据库初始化

```bash
npm run migrate
```

### 查看日志

```bash
# 所有日志
tail -f logs/combined.log

# 仅错误日志
tail -f logs/error.log
```

## 项目结构

```
server/
├── src/
│   ├── index.js              # Express服务器入口
│   ├── config/               # 配置文件
│   │   ├── database.js       # PostgreSQL连接池
│   │   ├── logger.js         # Winston日志
│   │   └── init.sql          # 数据库schema
│   ├── routes/               # API路由
│   │   ├── devices.js        # 设备注册
│   │   └── messages.js       # 消息管理
│   ├── services/             # 业务逻辑
│   │   ├── dataFetcher.js    # 数据采集
│   │   ├── llmProcessor.js   # LLM内容生成
│   │   ├── pushService.js    # APNs推送
│   │   └── scheduler.js      # 定时任务
│   └── middleware/           # 中间件
│       ├── auth.js           # API认证
│       ├── errorHandler.js   # 错误处理
│       └── rateLimiter.js    # 限流
├── certs/                    # APNs证书
│   └── AuthKey_4UMWA4C8CJ.p8
├── logs/                     # 日志目录
├── tests/                    # 测试文件
├── .env                      # 环境变量
├── package.json
└── README.md
```

## 核心配置

### 环境变量

当前配置（`.env`文件）：

```env
# 服务器
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

### LLM提供商切换

支持多个LLM提供商，通过`.env`配置：

```env
# 使用DeepSeek（默认）
LLM_PROVIDER=deepseek
LLM_MODEL=deepseek-chat
DEEPSEEK_API_KEY=your_key

# 或使用OpenAI
LLM_PROVIDER=openai
LLM_MODEL=gpt-4o-mini
OPENAI_API_KEY=your_key
```

### 数据库连接

```bash
# 连接数据库
psql -h localhost -U huiminzhang -d infodigest

# 查看表结构
\dt

# 查看消息
SELECT * FROM messages ORDER BY created_at DESC LIMIT 10;

# 查看设备
SELECT * FROM devices;

# 查看推送日志
SELECT * FROM push_logs ORDER BY created_at DESC LIMIT 10;
```

## API端点

### 公开端点

```http
GET  /api/messages              # 获取消息列表（分页）
GET  /api/messages/:id          # 获取消息详情
PUT  /api/messages/:id/read     # 标记已读
POST /api/devices/register     # 注册设备
```

### 管理端点（需要API Key）

```http
POST /api/admin/test-push      # 发送测试推送
POST /api/admin/run-digest     # 手动触发摘要生成
```

请求头需包含：
```http
X-API-Key: dev-admin-key-12345
```

## 定时任务

服务器使用cron定时任务每小时运行一次数据采集和推送。

修改频率（`.env`）：
```env
# 每小时
CRON_SCHEDULE=0 * * * *

# 每6小时
CRON_SCHEDULE=0 */6 * * *

# 每天9:00
CRON_SCHEDULE=0 9 * * *
```

## 测试和调试

### 测试API健康

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

### 手动触发摘要生成

```bash
curl -X POST http://localhost:3000/api/admin/run-digest \
  -H "X-API-Key: dev-admin-key-12345"
```

### 发送测试推送

```bash
curl -X POST http://localhost:3000/api/admin/test-push \
  -H "Content-Type: application/json" \
  -H "X-API-Key: dev-admin-key-12345" \
  -d '{"title":"测试","message":"测试消息"}'
```

### 测试设备注册

```bash
curl -X POST http://localhost:3000/api/devices/register \
  -H "Content-Type: application/json" \
  -d '{"deviceToken":"test_token","platform":"ios"}'
```

## 常用命令

### 开发

```bash
# 启动开发服务器（带自动重载）
npm run dev

# 启动生产服务器
npm start

# 运行测试（当实现时）
npm test
```

### 数据库

```bash
# 初始化数据库
npm run migrate

# 连接数据库
psql -h localhost -U huiminzhang -d infodigest

# 查看最近消息
psql -h localhost -U huiminzhang -d infodigest -c \
  "SELECT title, created_at FROM messages ORDER BY created_at DESC LIMIT 5;"
```

### 日志

```bash
# 实时查看所有日志
tail -f logs/combined.log

# 实时查看错误日志
tail -f logs/error.log

# 查看最近50行日志
tail -50 logs/combined.log

# 搜索特定关键词
grep "push" logs/combined.log
grep "error" logs/error.log
```

## 故障排查

### 服务器无法启动

```bash
# 检查端口占用
lsof -i:3000

# 杀死占用进程
kill -9 <PID>

# 检查PostgreSQL状态
brew services list | grep postgresql

# 重启PostgreSQL
brew services restart postgresql@14
```

### 数据库连接失败

```bash
# 测试连接
psql -h localhost -U huiminzhang -c "SELECT version();"

# 检查数据库是否存在
psql -h localhost -U huiminzhang -l | grep infodigest
```

### APNs推送失败

```bash
# 检查Key文件权限
ls -la certs/AuthKey_4UMWA4C8CJ.p8

# 应该是 -rw------- (600)
chmod 600 certs/AuthKey_4UMWA4C8CJ.p8

# 查看推送日志
tail -50 logs/combined.log | grep -i "push"

# 检查设备是否注册
psql -h localhost -U huiminzhang -d infodigest -c "SELECT * FROM devices;"
```

### LLM API错误

服务器会自动降级到简单模式，不会中断推送。

查看详情：
```bash
tail -f logs/combined.log | grep -i llm
```

### 定时任务不运行

```bash
# 查看日志中的调度信息
grep "Scheduler" logs/combined.log

# 手动触发测试
curl -X POST http://localhost:3000/api/admin/run-digest \
  -H "X-API-Key: dev-admin-key-12345"
```

## 数据源配置

### NewsAPI

- 免费额度：每日100次请求
- 当前配置：已配置密钥
- 如需更换：更新`.env`中的`NEWS_API_KEY`

### Alpha Vantage（可选）

- 免费额度：每日25次请求
- 当前配置：占位符，需要实际密钥
- 如需使用：更新`.env`中的`STOCK_API_KEY`

## 部署

### 本地部署

```bash
# 启动服务器
npm start

# 或使用PM2（生产环境推荐）
npm install -g pm2
pm2 start src/index.js --name infodigest
pm2 save
pm2 startup
```

### 云部署（可选）

支持的平台：
- Railway
- Render
- Docker

详见根目录的README.md。

## 性能优化

### 数据库

```sql
-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_type ON messages(type);
CREATE INDEX IF NOT EXISTS idx_devices_token ON devices(device_token);
```

### 日志轮转

使用Winston的日志轮转功能，自动管理日志文件大小。

## 安全注意事项

### 敏感信息

- ❌ 不要提交`.env`文件到Git
- ❌ 不要提交APNs证书文件
- ✅ 使用`.env.example`作为模板
- ✅ 生产环境使用强密码和API Key

### API认证

管理端点使用API Key认证：
```http
X-API-Key: dev-admin-key-12345
```

生产环境应更改为强密钥。

## 开发路线图

- [ ] 添加单元测试
- [ ] 添加集成测试
- [ ] 实现Redis缓存
- [ ] 优化数据库查询
- [ ] 添加监控和告警
- [ ] 实现Web管理后台

## 快速命令参考

```bash
# 启动
npm run dev

# 查看日志
tail -f logs/combined.log

# 测试健康
curl http://localhost:3000/health

# 测试推送
curl -X POST http://localhost:3000/api/admin/test-push \
  -H "X-API-Key: dev-admin-key-12345" \
  -d '{"title":"测试","message":"测试"}'

# 手动生成摘要
curl -X POST http://localhost:3000/api/admin/run-digest \
  -H "X-API-Key: dev-admin-key-12345"

# 查看设备
psql -h localhost -U huiminzhang -d infodigest -c "SELECT * FROM devices;"

# 查看最新消息
psql -h localhost -U huiminzhang -d infodigest -c \
  "SELECT title, created_at FROM messages ORDER BY created_at DESC LIMIT 5;"
```
