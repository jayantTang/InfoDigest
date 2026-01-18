# InfoDigest v2.0 用户体验指南

## 🎯 快速开始

InfoDigest v2.0 是一个完整的智能投资监控系统，现在服务器正在运行：

- **服务器地址**: http://localhost:3000
- **API文档**: http://localhost:3000/api (通过各端点访问)
- **服务器状态**: ✅ 正在运行

---

## 📱 如何使用（iOS客户端）

### 1. 注册设备

首先需要在iOS设备上注册以接收推送通知：

```bash
POST /api/devices/register
Content-Type: application/json

{
  "device_token": "你的设备Token",
  "platform": "ios",
  "app_version": "1.0.0",
  "os_version": "17.0"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "userId": "用户UUID",
    "deviceId": "设备UUID",
    "message": "Device registered successfully"
  }
}
```

### 2. 配置用户偏好

```bash
PUT /api/users/{userId}/preferences
Content-Type: application/json

{
  "pushEnabled": true,
  "timezone": "Asia/Shanghai",
  "currency": "USD",
  "language": "zh-CN"
}
```

### 3. 创建投资组合

添加您的持仓到投资组合：

```bash
POST /api/portfolios/items
Content-Type: application/json

{
  "userId": "{userId}",
  "symbol": "NVDA",
  "shares": 10,
  "averageCost": 450.00,
  "assetType": "stock"
}
```

### 4. 创建关注列表

添加感兴趣的股票：

```bash
POST /api/watchlists/items
Content-Type: application/json

{
  "userId": "{userId}",
  "symbol": "TSLA",
  "notes": "电动汽车领头羊"
}
```

### 5. 设置监控策略

创建价格突破策略：

```bash
POST /api/strategies
Content-Type: application/json

{
  "userId": "{userId}",
  "symbol": "NVDA",
  "name": "NVDA突破900美元",
  "conditionType": "price",
  "conditions": {
    "priceAbove": 900
  },
  "action": "notify",
  "priority": 70
}
```

创建技术指标策略：

```bash
POST /api/strategies
Content-Type: application/json

{
  "userId": "{userId}",
  "symbol": "AAPL",
  "name": "AAPL RSI超卖信号",
  "conditionType": "technical",
  "conditions": {
    "rsi": {
      "below": 30
    }
  },
  "priority": 75
}
```

### 6. 创建临时关注

创建短期监控项目：

```bash
POST /api/temporary-focus
Content-Type: application/json

{
  "userId": "{userId}",
  "title": "科技股短期监控",
  "description": "监控主要科技股的价格异动",
  "targets": ["NVDA", "AAPL", "MSFT"],
  "focus": {
    "newsImpact": true,
    "priceReaction": true
  },
  "expiresAt": "2026-01-25T23:59:59Z"
}
```

---

## 🔧 核心功能演示

### 查看系统状态

```bash
# 健康检查
curl http://localhost:3000/health

# 监控引擎状态
curl http://localhost:3000/api/monitoring/status

# 数据采集状态
curl http://localhost:3000/api/data-collection/status
```

### 查看您的数据

```bash
# 查看投资组合
curl http://localhost:3000/api/portfolios?user_id={userId}

# 查看关注列表
curl http://localhost:3000/api/watchlists?user_id={userId}

# 查看策略
curl http://localhost:3000/api/strategies?user_id={userId}

# 查看临时关注
curl http://localhost:3000/api/temporary-focus?user_id={userId}
```

### 手动触发功能

```bash
# 触发数据采集（需要Admin API Key）
curl -X POST http://localhost:3000/api/data-collection/collect-all \
  -H "X-API-Key: dev-admin-key-12345"

# 手动执行监控检查
curl -X POST http://localhost:3000/api/monitoring/check-cycle \
  -H "X-API-Key: dev-admin-key-12345"

# 生成AI分析
curl -X POST http://localhost:3000/api/analysis/strategy/{strategyId}/generate \
  -H "X-API-Key: dev-admin-key-12345"
```

---

## 📊 系统功能概览

### 1. 数据采集系统（6个数据源）

- **Alpha Vantage**: 股票/ETF价格数据
- **CoinGecko**: 加密货币市场数据
- **NewsAPI**: 财经新闻
- **Technical Indicators**: 技术指标计算（RSI, MACD, 布林带等）
- **Sector Aggregator**: 板块数据聚合
- **FRED**: 宏观经济数据

### 2. 监控引擎

- **实时监控**: 每60秒检查一次
- **4种条件类型**: 价格、技术指标、新闻、时间
- **事件评分**: 0-100分的重要性评分
- **自动触发**: 条件满足时自动发送通知

### 3. 推送通知系统

- **优先级队列**: 高分优先
- **去重机制**: 5分钟去重窗口
- **失败重试**: 最多3次重试
- **批量发送**: 高效处理

### 4. AI分析系统

- **策略分析**: 触发原因、市场背景、技术分析、风险评估
- **关注报告**: 监控发现总结、相关性分析、行动建议
- **事件解读**: 影响评估、市场反应、未来展望
- **LLM集成**: 支持DeepSeek和OpenAI

---

## 🧪 测试API

### 测试数据采集

```bash
# 查看数据源状态
curl http://localhost:3000/api/data-collection/sources

# 查看健康状态
curl http://localhost:3000/api/data-collection/health

# 查看采集指标
curl http://localhost:3000/api/data-collection/metrics
```

### 测试监控功能

```bash
# 查看所有策略
curl http://localhost:3000/api/monitoring/strategies

# 查看监控指标
curl http://localhost:3000/api/monitoring/metrics

# 启动监控引擎
curl -X POST http://localhost:3000/api/monitoring/start \
  -H "X-API-Key: dev-admin-key-12345"

# 停止监控引擎
curl -X POST http://localhost:3000/api/monitoring/stop \
  -H "X-API-Key: dev-admin-key-12345"
```

### 测试AI分析

```bash
# 查看分析统计
curl http://localhost:3000/api/analysis/stats

# 查看事件分析
curl http://localhost:3000/api/analysis/events?limit=10
```

---

## 📱 完整使用流程示例

### 场景：监控NVDA股票

1. **注册设备** → 获取userId
2. **添加到投资组合** → 添加10股NVDA
3. **创建价格策略** → 设置突破$900提醒
4. **创建技术策略** → RSI超卖提醒
5. **系统自动监控** → 每60秒检查一次
6. **收到推送通知** → 条件满足时自动发送
7. **查看AI分析** → 深度解读触发原因
8. **获得投资建议** → 基于AI分析的行动建议

### 场景：临时关注科技股

1. **创建临时关注** → 关注NVDA、AAPL、MSFT
2. **设置监控重点** → 价格异动 + 新闻影响
3. **系统持续监控** → 检查重要新闻和价格变化
4. **收到即时通知** → 发现重要事件时推送
5. **查看分析报告** → 监控期结束生成总结
6. **获得行动建议** → AI提供的具体建议

---

## 🎯 策略类型说明

### 价格条件

```json
{
  "conditionType": "price",
  "conditions": {
    "priceAbove": 900,      // 价格突破900
    "priceBelow": 800,      // 价格跌破800
    "percentChange": 3      // 涨跌幅超过3%
  }
}
```

### 技术指标条件

```json
{
  "conditionType": "technical",
  "conditions": {
    "rsi": {
      "above": 70,          // RSI超过70（超买）
      "below": 30           // RSI低于30（超卖）
    },
    "macd": {
      "crossoverAbove": true, // MACD金叉
      "crossoverBelow": true  // MACD死叉
    }
  }
}
```

### 新闻条件

```json
{
  "conditionType": "news",
  "conditions": {
    "minImportance": 70,     // 最低重要性70分
    "categories": ["earnings", "merger"]  // 指定分类
  }
}
```

### 时间条件

```json
{
  "conditionType": "time",
  "conditions": {
    "timeRange": {
      "start": "09:30",
      "end": "16:00"
    },
    "dayOfWeek": 1  // 星期一
  }
}
```

---

## 📞 API端点清单

### 用户管理 (10个端点)
- POST `/api/devices/register` - 注册设备
- GET `/api/users/:id` - 获取用户信息
- PUT `/api/users/:id/preferences` - 更新偏好
- GET `/api/portfolios` - 获取投资组合
- POST `/api/portfolios/items` - 添加持仓
- GET `/api/watchlists` - 获取关注列表
- POST `/api/watchlists/items` - 添加关注
- DELETE `/api/portfolios/items/:id` - 删除持仓
- DELETE `/api/watchlists/items/:id` - 删除关注
- GET `/api/users/:id/dashboard` - 用户仪表板

### 策略管理 (8个端点)
- GET `/api/strategies` - 获取策略列表
- POST `/api/strategies` - 创建策略
- GET `/api/strategies/:id` - 获取策略详情
- PUT `/api/strategies/:id` - 更新策略
- DELETE `/api/strategies/:id` - 删除策略
- PUT `/api/strategies/:id/status` - 更新状态
- GET `/api/strategies/:id/history` - 触发历史
- POST `/api/strategies/:id/test` - 测试策略

### 临时关注 (6个端点)
- GET `/api/temporary-focus` - 获取关注列表
- POST `/api/temporary-focus` - 创建关注
- GET `/api/temporary-focus/:id` - 获取详情
- PUT `/api/temporary-focus/:id` - 更新关注
- DELETE `/api/temporary-focus/:id` - 删除关注
- POST `/api/temporary-focus/:id/extend` - 延期

### 数据采集 (6个端点)
- GET `/api/data-collection/status` - 采集状态
- GET `/api/data-collection/sources` - 数据源状态
- GET `/api/data-collection/health` - 健康检查
- GET `/api/data-collection/metrics` - 采集指标
- POST `/api/data-collection/collect-all` - 触发全量采集
- POST `/api/data-collection/collect/:source` - 触发单源采集

### 监控引擎 (12个端点)
- GET `/api/monitoring/status` - 监控状态
- POST `/api/monitoring/start` - 启动监控
- POST `/api/monitoring/stop` - 停止监控
- POST `/api/monitoring/check-cycle` - 手动检查
- GET `/api/monitoring/strategies` - 激活策略
- GET `/api/monitoring/strategies/:id` - 策略详情
- POST `/api/monitoring/strategies/:id/test` - 测试策略
- GET `/api/monitoring/focus-items` - 临时关注
- GET `/api/monitoring/events` - 市场事件
- GET `/api/monitoring/queue` - 推送队列
- POST `/api/monitoring/queue/clear` - 清空队列
- GET `/api/monitoring/metrics` - 监控指标

### AI分析 (13个端点)
- GET `/api/analysis/stats` - 分析统计
- GET `/api/analysis/strategy/:id` - 策略分析
- POST `/api/analysis/strategy/:id/generate` - 生成分析
- GET `/api/analysis/user/:userId/strategies` - 用户策略分析
- GET `/api/analysis/focus/:id` - 关注分析
- POST `/api/analysis/focus/:id/generate` - 生成分析
- GET `/api/analysis/user/:userId/focus` - 用户关注分析
- GET `/api/analysis/event/:id` - 事件分析
- POST `/api/analysis/event/:id/generate` - 生成分析
- GET `/api/analysis/events` - 所有事件分析
- DELETE `/api/analysis/strategy/:id` - 删除分析
- DELETE `/api/analysis/focus/:id` - 删除分析
- DELETE `/api/analysis/event/:id` - 删除分析

---

## 💡 使用技巧

### 1. 优先级设置

- **90-100**: 关键事件（策略触发 + 大幅异动）
- **70-89**: 重要事件（重要新闻、价格异动）
- **50-69**: 中等事件（技术信号、关注价位）
- **30-49**: 低优先级（普通事件）
- **0-29**: 最小优先级

### 2. 策略组合建议

**保守型**:
- 价格跌破支撑位
- RSI超卖（<30）
- 重要财报新闻

**激进型**:
- 价格突破阻力位
- RSI超买（>70）
- 成交量异常

**平衡型**:
- 价格突破 + 技术确认
- MACD金叉/死叉
- 板块联动效应

### 3. 临时关注使用场景

**财报季**: 关注相关公司财报前后的表现
**重大事件**: 监控突发事件对相关股票的影响
**板块轮动**: 追踪板块资金流向
**套利机会**: 监控相关公司的价差变化

---

## 📚 相关文档

- [Phase 1完成报告](docs/PHASE1_COMPLETION.md) - 用户配置系统
- [Phase 2完成报告](docs/PHASE2_COMPLETION.md) - 数据采集系统
- [Phase 3完成报告](docs/PHASE3_COMPLETION.md) - 监控引擎
- [Phase 4完成报告](docs/PHASE4_COMPLETION.md) - LLM分析系统
- [数据库Schema](docs/DATABASE_SCHEMA_V2.md) - 完整数据结构
- [API设计](docs/API_DESIGN.md) - API设计文档

---

## 🎉 享受智能投资监控！

InfoDigest v2.0 会24/7自动监控市场，当您设置的条件满足时会立即发送推送通知，并提供AI生成的深度分析和投资建议。

**开始使用**:
1. 在iOS设备上打开应用
2. 允许推送通知权限
3. 添加您的投资组合
4. 设置监控策略
5. 系统自动开始监控
6. 接收智能通知和AI分析

**祝投资顺利！** 📈
