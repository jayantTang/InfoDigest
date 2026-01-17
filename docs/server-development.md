# InfoDigest Server

智能信息摘要推送服务 - 数据采集、LLM处理和APNs推送。

## 功能特性

- ✅ 定时数据采集（新闻API、股票API）
- ✅ LLM智能内容生成（支持DeepSeek/OpenAI/本地模型）
- ✅ APNs推送通知
- ✅ PostgreSQL数据持久化
- ✅ Redis缓存支持
- ✅ RESTful API
- ✅ Cron定时任务调度

## 技术栈

- **运行时**: Node.js 18+
- **框架**: Express.js
- **数据库**: PostgreSQL 14+
- **缓存**: Redis 7+
- **LLM**: DeepSeek API (推荐) / OpenAI API (可选)
- **推送**: APNs (Apple Push Notification Service)

## 快速开始

### 1. 安装依赖

```bash
cd server
npm install
```

### 2. 环境配置

复制环境变量模板：
```bash
cp .env.example .env
```

编辑 `.env` 文件，填入必要的配置：

```env
# Server
NODE_ENV=development
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=infodigest
DB_USER=postgres
DB_PASSWORD=your_password

# API Keys
NEWS_API_KEY=your_newsapi_key
STOCK_API_KEY=your_alphavantage_key
OPENAI_API_KEY=your_openai_key

# APNs
APNS_KEY_ID=your_key_id
APNS_TEAM_ID=your_team_id
APNS_BUNDLE_ID=com.yourcompany.InfoDigest
APNS_KEY_PATH=./certs/AuthKey_KEY_ID.p8
APNS_PRODUCTION=false
```

### 3. 安装和配置PostgreSQL

#### macOS (Homebrew)
```bash
brew install postgresql@14
brew services start postgresql@14

# Create database
psql postgres
CREATE DATABASE infodigest;
\q
```

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql

# Create database
sudo -u postgres psql
CREATE DATABASE infodigest;
\q
```

#### Docker
```bash
docker run -d \
  --name infodigest-postgres \
  -e POSTGRES_PASSWORD=your_password \
  -e POSTGRES_DB=infodigest \
  -p 5432:5432 \
  postgres:14-alpine
```

### 4. 初始化数据库

```bash
npm run migrate
```

这将创建所有必要的表和示例数据。

### 5. 安装和配置Redis

#### macOS (Homebrew)
```bash
brew install redis
brew services start redis
```

#### Ubuntu/Debian
```bash
sudo apt install redis-server
sudo systemctl start redis
```

#### Docker
```bash
docker run -d \
  --name infodigest-redis \
  -p 6379:6379 \
  redis:7-alpine
```

### 6. 配置APNs推送证书

1. 登录 [Apple Developer](https://developer.apple.com)
2. 创建 App ID，启用 Push Notifications 能力
3. 创建推送密钥（.p8文件）：
   - Keys → Create a Key
   - 选择 Apple Push Notifications service (APNs)
   - 下载密钥文件，保存到 `server/certs/` 目录
4. 更新 `.env` 中的APNs配置：
   ```
   APNS_KEY_ID=your_key_id
   APNS_TEAM_ID=your_team_id
   APNS_BUNDLE_ID=com.yourcompany.InfoDigest
   APNS_KEY_PATH=./certs/AuthKey_YOUR_KEY_ID.p8
   ```

### 7. 获取API密钥

#### NewsAPI.org
1. 访问 [NewsAPI](https://newsapi.org)
2. 注册账号
3. 获取免费API Key
4. 填入 `.env` 的 `NEWS_API_KEY`

#### Alpha Vantage (股票数据)
1. 访问 [Alpha Vantage](https://www.alphavantage.co/support/#api-key)
2. 免费获取API Key
3. 填入 `.env` 的 `STOCK_API_KEY`

#### DeepSeek API (推荐 - 已配置)
项目已配置DeepSeek API，具有以下优势：
- ✅ 性价比极高（输入: ¥1/百万tokens，输出: ¥2/百万tokens）
- ✅ 优秀的中文理解能力
- ✅ 与OpenAI API兼容

配置已默认设置，无需额外操作。

如需使用OpenAI（可选）：
1. 访问 [OpenAI Platform](https://platform.openai.com)
2. 创建API Key
3. 修改 `.env`：`LLM_PROVIDER=openai`
4. 填入 `OPENAI_API_KEY`

### 8. 启动服务器

```bash
# 开发模式（带自动重载）
npm run dev

# 生产模式
npm start
```

服务器将在 `http://localhost:3000` 启动。

### 9. 测试

#### 测试数据库连接
访问：`http://localhost:3000/health`

#### 测试推送通知（需要先注册设备）
```bash
curl -X POST http://localhost:3000/api/admin/test-push \
  -H "Content-Type: application/json" \
  -d '{"title": "测试推送", "message": "这是一条测试消息"}'
```

#### 测试生成摘要
```bash
curl -X POST http://localhost:3000/api/admin/run-digest
```

## API文档

### 设备管理

#### 注册设备
```http
POST /api/devices/register
Content-Type: application/json

{
  "deviceToken": "device_token_string",
  "platform": "ios",
  "appVersion": "1.0.0",
  "osVersion": "17.0"
}
```

### 消息管理

#### 获取消息列表
```http
GET /api/messages?page=1&limit=20&type=news
```

#### 获取消息详情
```http
GET /api/messages/:id
```

#### 标记消息已读
```http
PUT /api/messages/:id/read
Content-Type: application/json

{
  "deviceId": "device_uuid"
}
```

## 定时任务

服务器默认配置为**每小时**运行一次数据采集和推送。

修改 `.env` 中的 `CRON_SCHEDULE` 来调整频率：

```env
# 每小时
CRON_SCHEDULE=0 * * * *

# 每6小时
CRON_SCHEDULE=0 */6 * * *

# 每天9:00
CRON_SCHEDULE=0 9 * * *
```

## 部署到生产环境

### 使用 Railway

1. 连接GitHub仓库到Railway
2. 添加以下环境变量
3. Railway会自动检测Node.js并部署

### 使用 Render

1. 在Render创建新的Web Service
2. 连接GitHub仓库
3. 设置环境变量和构建命令
4. 部署！

### 使用 Docker

```bash
# 构建镜像
docker build -t infodigest-server .

# 运行容器
docker run -d \
  --name infodigest \
  --env-file .env \
  -p 3000:3000 \
  infodigest-server
```

## 监控和日志

日志文件保存在 `server/logs/` 目录：
- `combined.log` - 所有日志
- `error.log` - 仅错误日志

查看实时日志：
```bash
tail -f logs/combined.log
```

## 故障排查

### 数据库连接失败
```bash
# 检查PostgreSQL是否运行
psql -h localhost -U postgres -c "SELECT version();"
```

### APNs推送失败
- 确认设备Token正确
- 检查Bundle ID是否匹配
- 确认推送证书有效

### LLM API错误
- 检查DeepSeek API Key是否有效（已配置）
- 验证API密钥余额和额度
- 服务器会自动降级到简单模式
- 如需切换LLM提供商，修改`.env`中的`LLM_PROVIDER`

## 许可证

MIT License
