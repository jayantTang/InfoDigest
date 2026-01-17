# InfoDigest v2.0 升级指南

## 版本概述

InfoDigest v2.0 是一次重大升级，从"新闻摘要应用"转变为"智能投资监控系统"。

### 主要变化

**v1.0 (旧版本):**
- 每小时推送新闻和股票摘要
- 被动接收信息
- 内容泛化，无个性化

**v2.0 (新版本):**
- 双通道推送（即时+定时）
- 主动投资监控
- 完全个性化的投资分析
- 支持股票、加密货币、宏观等多资产

---

## 升级前准备

### 1. 数据备份

```bash
# 备份数据库
pg_dump -h localhost -U huiminzhang infodigest > backup_v1_$(date +%Y%m%d).sql

# 或使用备份脚本
cd server
./scripts/backup-db.sh
```

### 2. 代码备份

```bash
# 创建备份分支
git checkout -b backup/v1
git push origin backup/v1

# 回到主分支
git checkout master
```

### 3. 确认依赖

```bash
# Node.js版本需要 >= 18
node --version

# PostgreSQL版本需要 >= 14
psql --version
```

---

## 升级步骤

### Step 1: 更新数据库Schema

```bash
cd server

# 执行迁移脚本
psql -h localhost -U huiminzhang -d infodigest \
  -f src/config/migrations/001_initial_schema_v2.sql

# 验证表创建
psql -h localhost -U huiminzhang -d infodigest -c "\dt"

# 应该看到新的表：
# - portfolios
# - watchlists
# - strategies
# - temporary_focus
# - assets
# - crypto_assets
# - analyses
# - 等等...
```

### Step 2: 更新服务器代码

```bash
# 更新依赖（新增的包）
cd server
npm install

# 检查环境变量
cat .env

# 确保包含新的配置：
# COINGECKO_API_KEY=xxx
# FRED_API_KEY=xxx (可选)
```

### Step 3: 更新iOS客户端

```bash
cd InfoDigest

# 更新Bundle ID等配置（如果需要）
# 打开Xcode项目
open InfoDigest.xcodeproj

# 检查并更新：
# - APIService.baseURL
# - 数据模型（新的字段）
# - UI界面
```

### Step 4: 测试迁移

```bash
# 1. 重启服务器
cd server
./scripts/stop-server.sh
./scripts/start-server.sh

# 2. 测试API
curl http://localhost:3000/health

# 3. 测试数据库连接
./scripts/db-shell.sh
> \dt
> \q

# 4. 测试LLM连接
curl -X POST http://localhost:3000/api/admin/test-llm
```

---

## 数据迁移

### 旧数据如何处理

#### Messages表 -> Analyses表

旧版本的`messages`表不再使用，但数据会迁移到新的`analyses`表：

```sql
-- 迁移脚本
INSERT INTO analyses (user_id, analysis_type, content, summary, created_at)
SELECT
    (SELECT id FROM users LIMIT 1),
    'historical',
    jsonb_build_object(
        'title', title,
        'content', content_rich,
        'summary', summary,
        'images', images,
        'links', links
    ),
    summary,
    created_at
FROM messages_v1;
```

#### Devices表 -> Users表

旧的`devices`表数据迁移到新的`users`表：

```sql
INSERT INTO users (email, device_id, push_token)
SELECT email, id, device_token
FROM devices_v1
ON CONFLICT (email) DO NOTHING;
```

### 保留旧表

迁移后，旧表会保留（重命名为`_v1`）：

```sql
-- 旧表会自动重命名
ALTER TABLE messages RENAME TO messages_v1;
ALTER TABLE devices RENAME TO devices_v1;
ALTER TABLE push_logs RENAME TO push_logs_v1;
```

**建议：**
- 保留1-2个月
- 确认新系统稳定后再删除
- 删除前再次备份

---

## 新功能配置

### 1. 用户配置

用户需要在App中配置：

**我的投资组合**
```
持仓:
- NVDA 100股 @ $880
- TSLA 50股 @ $250
- BTC 0.5个 @ $45000
```

**我的关注**
```
关注列表:
- AMD (潜在买入)
- SOXX ETF (半导体板块)
- ETH (观察)
```

**我的策略**
```
策略1: NVDA突破$900加仓
策略2: BTC跌破$40000止损
策略3: AMD财报发布日关注
```

**临时关注**
```
"关注AMD财报对NVDA的影响"
- 有效期: 今天
- 重点: 竞争、价格对比
```

### 2. 推送设置

在App的"设置"中：

**推送频率**
- 正常模式（推荐）
- 极简模式（只推重要）
- 全部推送（所有更新）

**分析长度**
- 完整版（2000字，详细）
- 精简版（500字，快速）

**免打扰**
- 可设置时间段
- 重大事件仍会推送

---

## 功能对比

| 功能 | v1.0 | v2.0 |
|------|------|------|
| 推送方式 | 定时（每小时） | 双通道（即时+定时） |
| 内容类型 | 新闻摘要 | 投资分析+操作建议 |
| 个性化 | 无 | 完全个性化 |
| 支持资产 | 股票、ETF | 股票、ETF、加密货币、宏观 |
| 用户配置 | 无 | 持仓、关注、策略 |
| 学习能力 | 无 | 有（反馈学习） |
| 板块分析 | 简单 | 深入（估值、资金流） |
| 技术分析 | 无 | 有（RSI、MACD等） |
| 操作建议 | 无 | 有（具体可执行） |

---

## API变化

### 新增端点

#### 用户配置
```http
POST /api/portfolios
GET /api/portfolios
PUT /api/portfolios/:id
DELETE /api/portfolios/:id

POST /api/watchlists
GET /api/watchlists
PUT /api/watchlists/:id
DELETE /api/watchlists/:id

POST /api/strategies
GET /api/strategies
PUT /api/strategies/:id
DELETE /api/strategies/:id

POST /api/temporary-focus
GET /api/temporary-focus
```

#### 分析和推送
```http
GET /api/analyses?limit=20
GET /api/analyses/:id
POST /api/analyses/:id/feedback
```

#### 市场数据
```http
GET /api/assets/:symbol
GET /api/assets/:symbol/price
GET /api/assets/:symbol/technical
GET /api/sectors
GET /api/sectors/:id/performance
```

#### 加密货币
```http
GET /api/crypto
GET /api/crypto/:symbol
GET /api/crypto/:symbol/onchain
```

### 修改的端点

#### 设备注册（现在注册用户配置）
```http
POST /api/devices/register

新请求体：
{
  "deviceToken": "xxx",
  "platform": "ios",

  // 新增：用户初始配置
  "initialConfig": {
    "portfolio": [...],
    "watchlist": [...],
    "preferences": {...}
  }
}
```

### 移除的端点

```http
# 旧的messages端点不再使用
GET /api/messages     → GET /api/analyses
GET /api/messages/:id → GET /api/analyses/:id
```

---

## 回滚计划

如果升级后出现问题：

### 1. 快速回滚服务器

```bash
cd server
git checkout backup/v1
./scripts/restart-server.sh
```

### 2. 恢复数据库

```bash
# 恢复备份
psql -h localhost -U huiminzhang infodigest < backup_v1_YYYYMMDD.sql

# 或者重命名表回来
psql -h localhost -U huiminzhang infodigest
DROP TABLE messages CASCADE;
ALTER TABLE messages_v1 RENAME TO messages;
```

### 3. 回滚iOS客户端

```bash
cd InfoDigest
git checkout backup/v1
./scripts/build-ios.sh
```

---

## 常见问题

### Q1: 升级后我的旧数据会丢失吗？

**A:** 不会。旧的messages和devices数据会自动迁移到新表。旧表会保留为`_v1`后缀，直到你确认删除。

### Q2: 我需要重新配置所有内容吗？

**A:** 是的，新的配置更强大：
- 需要设置你的持仓（如果你有的话）
- 需要设置你的关注列表
- 可以设置投资策略
- 旧的"设备注册"会自动迁移

### Q3: 推送会变多吗？

**A:** 默认情况下不会。你可以：
- 选择推送频率（正常/极简/全部）
- 设置免打扰时间
- 系统只会推送真正重要的内容

### Q4: 加密货币是强制的吗？

**A:** 不是。你可以在设置中关闭：
```json
"content_types": {
  "crypto": false  // 关闭加密货币
}
```

### Q5: 我的投资建议会自动执行吗？

**A:** 不会。系统只给建议，所有操作都由你自己决定和执行。

### Q6: 如果我不同意LLM的建议？

**A:**
1. 点击"反馈"告诉我们为什么
2. 系统会学习你的偏好
3. 未来的建议会更符合你的风格

---

## 性能考虑

### 数据库性能

新版本使用了：
- **分区表**: prices表按月分区，查询更快
- **索引优化**: 为常用查询添加了索引
- **缓存**: 技术指标等数据会缓存

### 服务器性能

- **异步任务**: Bull队列处理耗时任务
- **并发**: 数据采集并发执行
- **缓存**: Redis缓存热点数据

### 预期资源使用

```
CPU: 轻微增加（LLM调用）
内存: 增加 200-500MB（Redis + 队列）
磁盘: 增加 50-100MB/月（更多数据存储）
API调用: 显著增加（数据源 + LLM）
```

---

## 下一步

升级完成后：

1. **配置你的投资组合**
   - 添加持仓
   - 添加关注列表
   - 设置策略

2. **体验新功能**
   - 测试即时推送（触发策略时）
   - 查看定时分析（每小时）
   - 尝试加密货币监控

3. **训练系统**
   - 对推送给出反馈
   - 告诉系统你的操作
   - 让AI越来越懂你

4. **查看高级功能**
   - 板块分析
   - 技术指标
   - 宏观经济数据

---

## 需要帮助？

如果升级过程中遇到问题：

1. 查看 [故障排查文档](./SERVER_DEVELOPMENT.md#故障排查)
2. 检查日志：`tail -f server/logs/combined.log`
3. 提交Issue到GitHub

---

**祝升级顺利！🚀**
