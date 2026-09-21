# InfoDigest

投资信息监控平台。后端定时采集行情、新闻和宏观数据，按预设策略触发分析，用 DeepSeek 生成报告，通过 APNs 推到 iPhone。

## 组成

| 目录 | 技术栈 | 内容 |
|---|---|---|
| `server/` | Node.js · Express · PostgreSQL · Redis | 采集、策略引擎、LLM 分析、推送 |
| `InfoDigest/` | SwiftUI · MVVM | iOS 客户端 |
| `docs/` | — | 架构、API、数据库设计 |

## 后端

**10 个数据采集器**（`src/services/collectors/`）：价格、加密货币、指数、板块、大宗商品、宏观、新闻、技术指标、新浪财经。基于 `baseCollector.js` 的可插拔架构，并行采集。

其它服务：

- **监控引擎** —— 60 秒周期轮询，按策略触发（`monitoringEngine.js`）
- **事件评分** —— 市场事件按重要性打 0–100 分（`eventScoringEngine.js`）
- **LLM 分析** —— DeepSeek 集成，生成分析报告（`llmAnalysisService.js`）
- **推送队列** —— APNs，带重试（`pushNotificationQueue.js`）

## iOS 客户端

SwiftUI + MVVM。模块：仪表板、机会、组合、关注列表、策略、临时关注、监控、设置。

## 快速开始

```bash
cd server
npm install
cp .env.example .env     # 填 PostgreSQL / Redis / DeepSeek / APNs
npm run migrate
npm run dev
```

依赖 PostgreSQL 和 Redis，也可以用 `npm run docker:up` 起容器。

iOS 端：`open InfoDigest/InfoDigest.xcodeproj`

## 测试

```bash
cd server && npm test
```

## 文档

[架构](docs/ARCHITECTURE_V2.md) · [API](docs/API_DESIGN.md) · [数据库](docs/DATABASE_SCHEMA_V2.md) · [DeepSeek 集成](docs/deepseek-integration.md) · [服务端](docs/server-development.md) · [iOS](docs/ios-development.md)

## 状态

v2.0，主要功能完成。2026-01 后未继续开发。
