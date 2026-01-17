# InfoDigest v2.0 API设计文档

## 文档信息

- **API版本**: v2.0
- **Base URL**: `http://localhost:3000/api` (开发)
- **生产URL**: `https://api.infodigest.com/api`
- **认证方式**: Device Token
- **数据格式**: JSON

---

## 1. API设计原则

### 1.1 RESTful规范

```
- 使用HTTP动词表示操作
  GET: 查询
  POST: 创建
  PUT/PATCH: 更新
  DELETE: 删除

- 资源命名使用复数名词
  /api/portfolios
  /api/strategies

- 使用HTTP状态码表示结果
  200: 成功
  201: 创建成功
  400: 请求错误
  401: 未认证
  403: 无权限
  404: 未找到
  500: 服务器错误

- 统一的响应格式
```

### 1.2 统一响应格式

**成功响应：**
```json
{
  "success": true,
  "data": { /* 业务数据 */ }
}
```

**分页响应：**
```json
{
  "success": true,
  "data": { /* 业务数据 */ },
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

**错误响应：**
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "请求参数验证失败",
    "details": {
      "field": "shares",
      "reason": "必须大于0"
    }
  }
}
```

### 1.3 认证方式

**Device Token认证：**
```
所有请求必须在Header中包含：
X-Device-Token: <device_token>

或者作为查询参数：
?device_token=<device_token>
```

### 1.4 通用参数

**分页参数：**
```
?page=1&limit=20

默认: page=1, limit=20

最大limit: 100
```

**排序参数：**
```
?sort=created_at&order=desc

支持的sort字段: created_at, updated_at, name, symbol等
```

**过滤参数：**
```
?status=active
?asset_type=stock
?category=technology
```

---

## 2. 用户配置API

### 2.1 用户注册和配置

#### POST /api/users/register

注册新用户（实际上是设备注册，自动创建用户）。

**请求体：**
```json
{
  "deviceToken": "4f3a8b9c-2d1e-4a5f-8c7b-9d6e3f1a2b4c5",
  "platform": "ios",
  "appVersion": "2.0.0",
  "osVersion": "17.0",

  // 初始配置（可选）
  "initialConfig": {
    "portfolio": [
      {
        "symbol": "NVDA",
        "assetType": "stock",
        "exchange": "NASDAQ",
        "shares": 100,
        "avgCost": 880.00
      }
    ],
    "watchlist": [
      {
        "symbol": "AMD",
        "assetType": "stock",
        "reason": "potential_buy"
      }
    ],
    "preferences": {
      "riskProfile": "neutral",
      "pushFrequency": "normal"
    }
  }
}
```

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "userId": "uuid-uuid-uuid-uuid",
    "deviceId": "uuid-uuid-uuid-uuid",
    "isNewUser": true,
    "preferences": {
      "analysisLength": "full",
      "pushFrequency": "normal",
      "quietHours": {
        "enabled": false,
        "start": "22:00",
        "end": "08:00"
      },
      "riskProfile": "neutral",
      "contentTypes": {
        "stocks": true,
        "crypto": true,
        "news": true,
        "technical": true,
        "fundamental": true
      }
    }
  }
}
```

**错误响应：**
- 400: 无效的device_token
- 409: device_token已存在

---

#### GET /api/users/profile

获取当前用户信息和配置。

**请求头：**
```
X-Device-Token: <device_token>
```

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": null,
      "deviceId": "uuid",
      "createdAt": "2025-01-18T10:00:00Z"
    },
    "preferences": {
      "analysisLength": "full",
      "pushFrequency": "normal",
      "quietHours": { /* ... */ },
      "riskProfile": "neutral",
      "contentTypes": { /* ... */ }
    },
    "learnedProfile": {
      "decisionStyle": "快速执行",
      "usefulAnalysis": ["技术面", "板块分析"],
      "suggestionAcceptanceRate": 0.75
    },
    "statistics": {
      "portfolioCount": 3,
      "watchlistCount": 5,
      "strategyCount": 2,
      "temporaryFocusCount": 1
    }
  }
}
```

---

#### PUT /api/users/profile

更新用户配置。

**请求体：**
```json
{
  "preferences": {
    "analysisLength": "summary",
    "pushFrequency": "minimal",
    "quietHours": {
      "enabled": true,
      "start": "23:00",
      "end": "07:00"
    },
    "riskProfile": "aggressive",
    "contentTypes": {
      "stocks": true,
      "crypto": false
    }
  }
}
```

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "preferences": { /* 更新后的配置 */ }
  }
}
```

---

### 2.2 持仓管理 (Portfolios)

#### GET /api/portfolios

获取用户的所有持仓。

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "portfolios": [
      {
        "id": "uuid",
        "symbol": "NVDA",
        "assetType": "stock",
        "exchange": "NASDAQ",
        "shares": 100,
        "avgCost": 880.00,
        "currentPrice": 895.00,
        "unrealizedPnl": 1500.00,
        "totalValue": 89500.00,
        "openedAt": "2025-01-10T10:00:00Z",
        "lastUpdated": "2025-01-18T15:30:00Z",
        "alerts": {
          "priceAbove": 900,
          "priceBelow": 800,
          "percentChange": 5,
          "volumeSpike": true
        },
        "status": "active"
      }
    ],
    "summary": {
      "totalValue": 150000.00,
      "totalUnrealizedPnl": 5000.00,
      "count": 3
    }
  }
}
```

---

#### POST /api/portfolios

添加新持仓。

**请求体：**
```json
{
  "symbol": "TSLA",
  "assetType": "stock",
  "exchange": "NASDAQ",
  "shares": 50,
  "avgCost": 250.00,
  "alerts": {
    "priceAbove": 300,
    "priceBelow": 200,
    "percentChange": 10,
    "volumeSpike": true
  }
}
```

**响应（201）：**
```json
{
  "success": true,
  "data": {
    "portfolio": {
      "id": "uuid",
      "symbol": "TSLA",
      "shares": 50,
      "avgCost": 250.00,
      "currentPrice": 248.00,
      "unrealizedPnl": -100.00,
      "status": "active",
      "createdAt": "2025-01-18T16:00:00Z"
    }
  }
}
```

**错误响应：**
- 400: 无效的symbol或shares
- 409: symbol已存在（UNIQUE约束）

---

#### PUT /api/portfolios/:id

更新持仓（如加仓、修改成本）。

**请求体：**
```json
{
  "shares": 120,
  "avgCost": 875.00,
  "alerts": {
    "priceAbove": 950,
    "priceBelow": 850
  }
}
```

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "portfolio": { /* 更新后的持仓 */ }
  }
}
```

---

#### DELETE /api/portfolios/:id

删除持仓（清仓）。

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "deleted": true,
    "message": "持仓已删除"
  }
}
```

---

### 2.3 关注列表 (Watchlists)

#### GET /api/watchlists

获取关注列表。

**查询参数：**
```
?reason=potential_buy
?asset_type=stock
?sort=priority&order=desc
```

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "watchlist": [
      {
        "id": "uuid",
        "symbol": "AMD",
        "assetType": "stock",
        "exchange": "NASDAQ",
        "reason": "potential_buy",
        "notes": "AI芯片领域，可能成为NVDA的替代选择",
        "focus": {
          "price": true,
          "news": true,
          "technical": false,
          "sector": false
        },
        "priority": 8,
        "createdAt": "2025-01-15T10:00:00Z"
      }
    ]
  }
}
```

---

#### POST /api/watchlists

添加到关注列表。

**请求体：**
```json
{
  "symbol": "AAPL",
  "assetType": "stock",
  "reason": "potential_buy",
  "notes": "iPhone 16销量可能超预期",
  "focus": {
    "price": true,
    "news": true,
    "technical": true,
    "sector": true
  },
  "priority": 7
}
```

**响应（201）：**
```json
{
  "success": true,
  "data": {
    "watchlist": { /* 创建的关注项 */ }
  }
}
```

---

#### PUT /api/watchlists/:id

更新关注项。

**请求体：**
```json
{
  "notes": "更新备注",
  "priority": 9
}
```

---

#### DELETE /api/watchlists/:id

从关注列表删除。

---

### 2.4 策略管理 (Strategies)

#### GET /api/strategies

获取所有策略。

**查询参数：**
```
?status=active
?symbol=NVDA
```

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "strategies": [
      {
        "id": "uuid",
        "name": "NVDA突破加仓策略",
        "description": "当NVDA突破$900且RSI不超买时加仓",
        "symbol": "NVDA",
        "conditionType": "price",
        "conditions": {
          "priceAbove": 900,
          "rsi": {
            "below": 70
          }
        },
        "action": {
          "type": "buy",
          "amount": 20,
          "reason": "技术突破确认，上升趋势延续"
        },
        "status": "active",
        "priority": 9,
        "lastTriggeredAt": null,
        "triggerCount": 0,
        "createdAt": "2025-01-10T10:00:00Z"
      }
    ]
  }
}
```

---

#### POST /api/strategies

创建新策略。

**请求体：**
```json
{
  "name": "TSLA止损策略",
  "description": "当TSLA跌破$200时止损",
  "symbol": "TSLA",
  "conditionType": "price",
  "conditions": {
    "priceBelow": 200
  },
  "action": {
    "type": "sell",
    "amount": "all",
    "reason": "跌破支撑位，及时止损"
  },
  "priority": 10
}
```

**响应（201）：**
```json
{
  "success": true,
  "data": {
    "strategy": { /* 创建的策略 */ }
  }
}
```

---

#### PUT /api/strategies/:id

更新策略。

**请求体：**
```json
{
  "status": "paused",
  "priority": 8
}
```

---

#### DELETE /api/strategies/:id

删除策略。

---

### 2.5 临时关注 (Temporary Focus)

#### GET /api/temporary-focus

获取所有临时关注。

**查询参数：**
```
?status=monitoring
```

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "temporaryFocus": [
      {
        "id": "uuid",
        "title": "关注AMD财报对NVDA的影响",
        "description": "AMD今日盘后发布财报，可能对半导体板块和NVDA产生影响",
        "targets": {
          "symbols": ["AMD", "NVDA"],
          "keywords": ["财报", "竞争", "市场份额"],
          "timeframe": "today"
        },
        "focus": {
          "newsImpact": true,
          "priceReaction": true,
          "correlation": true,
          "sectorEffect": false
        },
        "expiresAt": "2025-01-18T23:59:59Z",
        "status": "monitoring",
        "findings": null,
        "createdAt": "2025-01-18T10:00:00Z"
      }
    ]
  }
}
```

---

#### POST /api/temporary-focus

创建临时关注。

**请求体：**
```json
{
  "title": "关注美联储讲话",
  "description": "关注鲍威尔今晚讲话对科技股的影响",
  "targets": {
    "symbols": ["QQQ", "XLK"],
    "keywords": ["美联储", "利率", "通胀"],
    "timeframe": "today"
  },
  "focus": {
    "newsImpact": true,
    "priceReaction": false,
    "correlation": false,
    "sectorEffect": true
  },
  "expiresAt": "2025-01-18T23:59:59Z"
}
```

**响应（201）：**
```json
{
  "success": true,
  "data": {
    "temporaryFocus": { /* 创建的临时关注 */ }
  }
}
```

---

#### PUT /api/temporary-focus/:id

更新临时关注（如延长过期时间）。

**请求体：**
```json
{
  "status": "extended",
  "expiresAt": "2025-01-19T23:59:59Z"
}
```

---

#### DELETE /api/temporary-focus/:id

取消临时关注。

---

## 3. 市场数据API

### 3.1 资产数据

#### GET /api/assets

搜索和获取资产信息。

**查询参数：**
```
?q=NVDA
?type=stock
?sector=technology
?limit=20
```

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "assets": [
      {
        "id": "uuid",
        "symbol": "NVDA",
        "name": "NVIDIA Corporation",
        "assetType": "stock",
        "exchange": "NASDAQ",
        "country": "US",
        "currency": "USD",
        "sector": "Technology",
        "industry": "Semiconductors",
        "tags": ["AI", "芯片", "GPU"],
        "marketCap": 2500000000000,
        "website": "https://www.nvidia.com",
        "isActive": true
      }
    ]
  }
}
```

---

#### GET /api/assets/:symbol

获取单个资产的详细信息。

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "asset": {
      "symbol": "NVDA",
      "name": "NVIDIA Corporation",
      // ... 基本信息
      "relatedSymbols": ["AMD", "INTC", "TSM"],
      "parentSymbol": null
    },
    "price": {
      "current": 895.00,
      "change": 15.00,
      "changePercent": 1.70,
      "open": 888.00,
      "high": 900.00,
      "low": 885.00,
      "volume": 28000000,
      "timestamp": "2025-01-18T16:00:00Z"
    },
    "technical": {
      "rsi": 65,
      "macd": 2.5,
      "macdSignal": 1.8,
      "sma20": 875.00,
      "bollingerUpper": 920.00,
      "bollingerLower": 830.00
    },
    "fundamental": {
      "pe": 65.5,
      "eps": 13.80,
      "roe": 45.2,
      "marketCap": 2500000000000
    }
  }
}
```

---

### 3.2 价格数据

#### GET /api/prices/:symbol

获取标的最新价格。

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "symbol": "NVDA",
    "price": {
      "current": 895.00,
      "change": 15.00,
      "changePercent": 1.70,
      "open": 888.00,
      "high": 900.00,
      "low": 885.00,
      "volume": 28000000,
      "timestamp": "2025-01-18T16:00:00Z"
    },
    "52Week": {
      "high": 950.00,
      "low": 400.00
    },
    "ytd": {
      "return": 45.5,
      "returnPercent": 45.5
    }
  }
}
```

---

#### GET /api/prices/:symbol/history

获取历史价格数据。

**查询参数：**
```
?period=1d
&limit=30
```

**period选项：**
- `1d`: 日线数据
- `1h`: 小时数据
- `5m`: 5分钟数据

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "symbol": "NVDA",
    "period": "1d",
    "prices": [
      {
        "timestamp": "2025-01-18T00:00:00Z",
        "open": 888.00,
        "high": 900.00,
        "low": 885.00,
        "close": 895.00,
        "volume": 28000000
      }
    ]
  }
}
```

---

### 3.3 技术指标

#### GET /api/technical/:symbol

获取技术指标。

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "symbol": "NVDA",
    "calculatedAt": "2025-01-18T15:00:00Z",
    "trend": {
      "sma5": 888.50,
      "sma10": 882.30,
      "sma20": 875.00,
      "sma50": 850.00,
      "ema12": 890.20,
      "ema26": 868.50,
      "trend": "上升",
      "signal": "金叉"
    },
    "momentum": {
      "rsi": 65,
      "macd": 2.5,
      "macdSignal": 1.8,
      "macdHistogram": 0.7,
      "signal": "偏强，未超买"
    },
    "volatility": {
      "bollingerUpper": 920.00,
      "bollingerMiddle": 880.00,
      "bollingerLower": 840.00,
      "atr": 15.5,
      "signal": "在中轨上方，相对稳定"
    },
    "volume": {
      "current": 28000000,
      "avg5": 25000000,
      "avg20": 22000000,
      "ratio": 1.27,
      "signal": "成交量高于平均"
    }
  }
}
```

---

### 3.4 板块数据

#### GET /api/sectors

获取所有板块。

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "sectors": [
      {
        "id": "uuid",
        "name": "半导体",
        "nameEn": "Semiconductor",
        "etfSymbol": "SOXX",
        "category": "technology"
      }
    ]
  }
}
```

---

#### GET /api/sectors/:id

获取板块详情。

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "sector": {
      "id": "uuid",
      "name": "半导体",
      "nameEn": "Semiconductor",
      "etfSymbol": "SOXX",
      "category": "technology"
    },
    "performance": {
      "returnPercent": 0.5,
      "avgPe": 28.5,
      "pePercentile": 65,
      "netInflow": 2300000.00,
      "institutionalInflow": 1800000.00,
      "advancingCount": 32,
      "decliningCount": 15,
      "breadth": "2.13:1"
    },
    "leaders": [
      {"symbol": "AMD", "change": 3.2, "reason": "财报超预期"},
      {"symbol": "ARM", "change": 2.1, "reason": "中国市场突破"}
    ],
    "laggards": [
      {"symbol": "INTC", "change": -0.8, "reason": "产能过剩"},
      {"symbol": "MU", "change": -0.5, "reason": "需求疲软"}
    ],
    "relatedSymbols": ["NVDA", "TSM", "ASML"],
    "date": "2025-01-18"
  }
}
```

---

#### GET /api/sectors/:id/performance

获取板块历史表现。

**查询参数：**
```
?period=7d
```

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "sectorId": "uuid",
    "sectorName": "半导体",
    "period": "7d",
    "performance": [
      {
        "date": "2025-01-18",
        "returnPercent": 0.5,
        "avgPe": 28.5,
        "netInflow": 2300000.00
      }
    ]
  }
}
```

---

### 3.5 新闻和事件

#### GET /api/news

获取新闻。

**查询参数：**
```
?symbols=NVDA,TSLA
?minImportance=70
?limit=20
```

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "news": [
      {
        "id": "uuid",
        "title": "AMD财报超预期，数据中心业务增长150%",
        "description": "AMD今日盘后发布财报...",
        "source": "Bloomberg",
        "url": "https://...",
        "category": "earnings",
        "importanceScore": 85,
        "symbols": ["AMD", "NVDA", "SOXX"],
        "sectors": ["半导体"],
        "publishedAt": "2025-01-18T16:30:00Z",
        "fetchedAt": "2025-01-18T16:35:00Z"
      }
    ]
  }
}
```

---

## 4. 分析和推送API

### 4.1 分析报告

#### GET /api/analyses

获取分析历史。

**查询参数：**
```
?page=1
&limit=20
&type=immediate
?symbols=NVDA
```

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "analyses": [
      {
        "id": "uuid",
        "analysisType": "immediate",
        "summary": "NVDA突破$900，建议加仓20股",
        "urgency": "high",
        "symbols": ["NVDA"],
        "createdAt": "2025-01-18T15:30:00Z",
        "pushSentAt": "2025-01-18T15:30:05Z",
        "pushOpenedAt": "2025-01-18T15:31:20Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 150
    }
  }
}
```

---

#### GET /api/analyses/:id

获取单个分析的完整内容。

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "analysis": {
      "id": "uuid",
      "analysisType": "immediate",
      "summary": "NVDA突破$900，建议加仓20股",
      "urgency": "high",
      "content": {
        "sections": [
          {
            "type": "position_analysis",
            "title": "持仓分析",
            "content": "Markdown格式的完整内容",
            "data": {
              "nvda": {
                "current": 895,
                "change": "+1.7%",
                "volume": "2800万",
                "rsi": 65
              }
            },
            "keyPoints": ["要点1", "要点2"]
          }
          // ... 其他sections
        ],
        "visualizations": [
          {
            "type": "chart",
            "title": "NVDA价格走势",
            "data": "chart_url"
          }
        ]
      },
      "userFeedback": null,
      "createdAt": "2025-01-18T15:30:00Z"
    }
  }
}
```

---

### 4.2 用户反馈

#### POST /api/analyses/:id/feedback

提交对分析的反馈。

**请求体：**
```json
{
  "feedbackType": "executed",
  "action": {
    "type": "buy",
    "amount": 20,
    "actualPrice": 903.00,
    "executedAt": "2025-01-18T16:00:00Z",
    "reason": "相信技术突破"
  }
}
```

**反馈类型选项：**
- `executed`: 已执行
- `not_executed`: 未执行
- `useful`: 有用
- `not_useful`: 没用

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "feedbackId": "uuid",
    "message": "反馈已收到"
  }
}
```

---

## 5. 加密货币API

### 5.1 加密货币基础

#### GET /api/crypto

获取加密货币列表。

**查询参数：**
```
?sector=meme
?market_cap_rank_top=20
```

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "cryptos": [
      {
        "id": "uuid",
        "symbol": "BTC",
        "name": "Bitcoin",
        "cryptoSector": "layer1",
        "marketCapRank": 1,
        "totalSupply": 21000000,
        "circulatingSupply": 19500000,
        "maxSupply": 21000000,
        "website": "https://bitcoin.org",
        "twitter": "@bitcoin"
      }
    ]
  }
}
```

---

#### GET /api/crypto/:symbol

获取单个加密货币详情。

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "crypto": {
      "symbol": "PEPE",
      "name": "Pepe",
      "cryptoSector": "meme",
      "marketCapRank": 45,
      "price": {
        "current": 0.0000018,
        "change": 0.0000006,
        "changePercent": 50.0,
        "24hVolume": 150000000,
        "marketCap": 750000000
      },
      "onchain": {
        "whaleActivity": "增加",
        "exchangeInflow": "500万PEPE流入交易所",
        "activeAddresses": 50000,
        "transactionCount": 150000
      },
      "sentiment": {
        "fearGreed": 85,
        "socialMentions": 15000,
        "socialMentionsChange": 800,
        "fundingRate": 0.0001,
        "openInterest": 50000000,
        "longShortRatio": 1.2
      }
    }
  }
}
```

---

### 5.2 板块监控

#### GET /api/crypto/sectors

获取加密货币板块。

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "sectors": [
      {
        "name": "Meme",
        "description": "Meme coins",
        "cryptos": ["DOGE", "SHIB", "PEPE", "FLOKI"],
        "totalMarketCap": 50000000000,
        "24hChange": 12.5
      },
      {
        "name": "AI",
        "description": "AI and blockchain",
        "cryptos": ["FET", "AGIX", "RNDR"],
        "totalMarketCap": 8000000000,
        "24hChange": 8.3
      }
    ]
  }
}
```

---

#### GET /api/crypto/sectors/:name

获取板块详情。

**查询参数：**
```
?name=Meme
```

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "sector": {
      "name": "Meme",
      "cryptos": [
        {
          "symbol": "PEPE",
          "priceChange": 45.0,
          "volume": 150000000
        }
      ],
      "totalMarketCap": 50000000000,
      "topCrypto": {
        "symbol": "PEPE",
        "dominance": 0.35
      }
    }
  }
}
```

---

## 6. 系统API

### 6.1 健康检查

#### GET /health

系统健康检查。

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "version": "2.0.0",
    "timestamp": "2025-01-18T16:00:00Z",
    "services": {
      "database": "connected",
      "redis": "connected",
      "llm": "available"
    }
  }
}
```

---

### 6.2 数据采集

#### POST /api/admin/collect-data

手动触发数据采集（测试用）。

**请求头：**
```
X-API-Key: dev-admin-key-12345
```

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "collectedAt": "2025-01-18T16:00:00Z",
    "prices": {
      "count": 50,
      "symbols": ["NVDA", "TSLA", "AAPL", ...]
    },
    "news": {
      "count": 20,
      "sources": ["NewsAPI", "Bloomberg"]
    },
    "crypto": {
      "count": 10,
      "sources": ["CoinGecko"]
    }
  }
}
```

---

#### POST /api/admin/generate-analysis

手动触发分析生成（测试用）。

**请求头：**
```
X-API-Key: dev-admin-key-12345
```

**请求体：**
```json
{
  "userId": "uuid"
}
```

**响应（200）：**
```json
{
  "success": true,
  "data": {
    "analysisId": "uuid",
    "generatedAt": "2025-01-18T16:00:00Z",
    "urgency": "normal",
    "summary": "分析摘要"
  }
}
```

---

## 7. 错误码

### 7.1 客户端错误 (4xx)

| 错误码 | HTTP状态 | 说明 |
|--------|---------|------|
| `INVALID_REQUEST` | 400 | 请求参数无效 |
| `UNAUTHORIZED` | 401 | 未认证（缺少device_token） |
| `FORBIDDEN` | 403 | 无权限 |
| `NOT_FOUND` | 404 | 资源不存在 |
| `CONFLICT` | 409 | 资源冲突（如symbol已存在） |
| `RATE_LIMIT_EXCEEDED` | 429 | 超过速率限制 |
| `VALIDATION_ERROR` | 400 | 数据验证失败 |

### 7.2 服务器错误 (5xx)

| 错误码 | HTTP状态 | 说明 |
|--------|---------|------|
| `INTERNAL_ERROR` | 500 | 服务器内部错误 |
| `DATABASE_ERROR` | 500 | 数据库错误 |
| `EXTERNAL_API_ERROR` | 502 | 外部API错误 |
| `LLM_ERROR` | 500 | LLM调用失败 |
| `SERVICE_UNAVAILABLE` | 503 | 服务不可用 |

---

## 8. 数据模型

### 8.1 请求模型

#### Portfolio (持仓)
```typescript
interface Portfolio {
  symbol: string;           // 股票代码
  assetType: AssetType;      // 资产类型
  exchange?: string;        // 交易所
  shares: number;           // 持仓数量
  avgCost: number;          // 平均成本
  alerts?: {
    priceAbove?: number;
    priceBelow?: number;
    percentChange?: number;
    volumeSpike?: boolean;
    earnings?: boolean;
  };
}

enum AssetType {
  STOCK = 'stock',
  ETF = 'etf',
  INDEX = 'index',
  CRYPTO = 'crypto',
  COMMODITY = 'commodity',
  FOREX = 'forex'
}
```

#### Watchlist (关注)
```typescript
interface Watchlist {
  symbol: string;
  assetType: AssetType;
  exchange?: string;
  reason?: WatchReason;
  notes?: string;
  focus?: {
    price?: boolean;
    news?: boolean;
    technical?: boolean;
    sector?: boolean;
  };
  priority?: number;       // 1-10
}

enum WatchReason {
  POTENTIAL_BUY = 'potential_buy',
  COMPETITOR = 'competitor',
  SECTOR_WATCH = 'sector_watch',
  SPECULATIVE = 'speculative'
}
```

#### Strategy (策略)
```typescript
interface Strategy {
  name: string;
  description?: string;
  symbol: string;
  conditionType: ConditionType;
  conditions: StrategyConditions;
  action: StrategyAction;
  priority?: number;       // 1-10
}

enum ConditionType {
  PRICE = 'price',
  TECHNICAL = 'technical',
  NEWS = 'news',
  TIME = 'time'
}

interface StrategyConditions {
  // 价格条件
  priceAbove?: number;
  priceBelow?: number;
  percentChange?: number;

  // 技术条件
  rsi?: { above?: number; below?: number };
  macd?: 'golden_cross' | 'death_cross';

  // 时间条件
  datetime?: string; // ISO8601
}

interface StrategyAction {
  type: 'buy' | 'sell' | 'hold' | 'adjust';
  amount?: number;
  percent?: number;
  reason: string;
}
```

#### TemporaryFocus (临时关注)
```typescript
interface TemporaryFocus {
  title: string;
  description?: string;
  targets: {
    symbols: string[];
    keywords?: string[];
    timeframe: 'today' | 'week' | 'ongoing';
  };
  focus: {
    newsImpact?: boolean;
    priceReaction?: boolean;
    correlation?: boolean;
    sectorEffect?: boolean;
  };
  expiresAt: string;        // ISO8601
}
```

### 8.2 响应模型

#### Analysis (分析)
```typescript
interface Analysis {
  id: string;
  analysisType: 'immediate' | 'hourly' | 'query';
  summary: string;
  urgency: 'low' | 'normal' | 'high';
  symbols: string[];
  content: AnalysisContent;
  userFeedback?: UserFeedback;
  createdAt: string;
}

interface AnalysisContent {
  sections: AnalysisSection[];
  visualizations: Visualization[];
}

interface AnalysisSection {
  type: 'position_analysis' | 'event_impact' | 'sector_analysis' | 'recommendation';
  title: string;
  content: string;          // Markdown格式
  data?: Record<string, any>;
  keyPoints?: string[];
}

interface Visualization {
  type: 'chart' | 'table' | 'timeline';
  title: string;
  data: string;             // URL或数据
}
```

---

## 9. API使用示例

### 9.1 完整的用户流程

**步骤1: 注册设备并配置**
```bash
curl -X POST http://localhost:3000/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "deviceToken": "4f3a8b9c-2d1e-4a5f-8c7b-9d6e3f1a2b4c5",
    "platform": "ios",
    "appVersion": "2.0.0",
    "osVersion": "17.0",
    "initialConfig": {
      "portfolio": [
        {
          "symbol": "NVDA",
          "assetType": "stock",
          "shares": 100,
          "avgCost": 880.00
        }
      ]
    }
  }'
```

**步骤2: 添加关注**
```bash
curl -X POST http://localhost:3000/api/watchlists \
  -H "Content-Type: application/json" \
  -H "X-Device-Token: 4f3a8b9c-2d1e-4a5f-8c7b-9d6e3f1a2b4c5" \
  -d '{
    "symbol": "AMD",
    "assetType": "stock",
    "reason": "potential_buy",
    "priority": 8
  }'
```

**步骤3: 创建策略**
```bash
curl -X POST http://localhost:3000/api/strategies \
  -H "Content-Type: application/json" \
  -H "X-Device-Token: 4f3a8b9c-2d1e-4a5f-8c7b-9d6e3f1a2b4c5" \
  -d '{
    "name": "NVDA突破加仓策略",
    "symbol": "NVDA",
    "conditionType": "price",
    "conditions": {
      "priceAbove": 900
    },
    "action": {
      "type": "buy",
      "amount": 20,
      "reason": "技术突破确认"
    },
    "priority": 9
  }'
```

**步骤4: 查看分析**
```bash
curl -X GET http://localhost:3000/api/analyses \
  -H "X-Device-Token: 4f3a8b9c-2d1e-4a5f-8c7b-9d6e3f1a2b4c5" \
  -G "?limit=10"
```

**步骤5: 反馈**
```bash
curl -X POST http://localhost:3000/api/analyses/:id/feedback \
  -H "Content-Type: application/json" \
  -H "X-Device-Token: 4f3a8b9c-2d1e-4a5f-8c7b-9d6e3f1a2b4c5" \
  -d '{
    "feedbackType": "executed",
    "action": {
      "type": "buy",
      "amount": 20,
      "actualPrice": 903.00
    }
  }'
```

### 9.2 加密货币监控

**步骤1: 查看加密货币**
```bash
curl -X GET http://localhost:3000/api/crypto \
  -H "X-Device-Token: 4f3a8b9c-2d1e-4a5f-8c7b-9d6e3f1a2b4c5"
```

**步骤2: 查看Meme板块**
```bash
curl -X GET http://localhost:3000/api/crypto/sectors/Meme \
  -H "X-Device-Token: 4f3a8b9c-2d1e-4a5f-8c7b-9d6e3f1a2b4c5"
```

---

## 10. 测试脚本

创建API测试脚本（`server/scripts/test-api-v2.sh`）：

```bash
#!/bin/bash

# InfoDigest v2.0 API测试脚本

BASE_URL="http://localhost:3000/api"
DEVICE_TOKEN="4f3a8b9c-2d1e-4a5f-8c7b-9d6e3f1a2b4c5"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

test_endpoint() {
    local name=$1
    local method=$2
    local endpoint=$3
    local data=$4

    echo -n "测试 $name... "

    if [ -z "$data" ]; then
        response=$(curl -s -X "$method" "$BASE_URL$endpoint" \
            -H "X-Device-Token: $DEVICE_TOKEN")
    else
        response=$(curl -s -X "$method" "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -H "X-Device-Token: $DEVICE_TOKEN" \
            -d "$data")
    fi

    if echo "$response" | jq -e '.success' > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        echo -e "  ${YELLOW}响应: $response${NC}"
        return 1
    fi
}

echo "=== InfoDigest v2.0 API 测试 ==="
echo ""

# 1. 用户API
echo "1. 用户配置API"
test_endpoint "获取用户信息" "GET" "/users/profile"

# 2. 持仓API
echo ""
echo "2. 持仓管理API"
test_endpoint "获取持仓列表" "GET" "/portfolios"

# 3. 关注列表API
echo ""
echo "3. 关注列表API"
test_endpoint "获取关注列表" "GET" "/watchlists"

# 4. 策略API
echo ""
echo "4. 策略管理API"
test_endpoint "获取策略列表" "GET" "/strategies"

# 5. 资产数据API
echo ""
echo "5. 资产数据API"
test_endpoint "获取NVDA信息" "GET" "/assets/NVDA"

# 6. 价格API
echo ""
echo "6. 价格数据API"
test_endpoint "获取NVDA价格" "GET" "/prices/NVDA"

# 7. 技术指标API
echo ""
echo "7. 技术指标API"
test_endpoint "获取NVDA技术指标" "GET" "/technical/NVDA"

# 8. 板块API
echo ""
echo "8. 板块数据API"
test_endpoint "获取板块列表" "GET" "/sectors"

# 9. 加密货币API
echo ""
echo "9. 加密货币API"
test_endpoint "获取加密货币列表" "GET" "/crypto"

echo ""
echo "=== 测试完成 ==="
```

---

## 11. API版本控制

### 11.1 版本策略

- **主版本号**: 重大架构变更（如v1 → v2）
- **次版本号**: 新增功能
- **修订号**: Bug修复

### 11.2 版本兼容

**v2.0 breaking changes:**
- `/api/messages` → `/api/analyses`
- `/api/devices/register` → `/api/users/register`
- 响应格式统一为`{success, data}`
- 所有响应包含HTTP状态码

**向后兼容：**
- v1的messages端点保留但标记为deprecated
- v1设备可以继续使用v1端点（功能受限）

---

## 12. 速率限制

### 12.1 限制规则

**按用户：**
```
每分钟: 100请求
每小时: 1000请求
每天: 5000请求
```

**按端点：**
```
数据采集API: 10次/分钟
分析生成API: 5次/分钟
推送API: 20次/分钟
```

### 12.2 超限响应

**响应（429）：**
```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "超过速率限制",
    "details": {
      "limit": 100,
      "window": "1分钟",
      "retryAfter": 60
    }
  }
}
```

---

## 13. 安全考虑

### 13.1 认证

- Device Token唯一标识用户
- Token在注册时绑定到userId
- Token失效后需重新注册

### 13.2 数据隔离

- 所有查询自动过滤user_id
- 用户只能访问自己的数据
- 跨用户访问返回403

### 13.3 输入验证

- 所有输入参数验证
- SQL注入防护
- XSS防护
- CSRF防护（如果使用session）

---

## 14. 测试环境

### 14.1 本地测试

```
Base URL: http://localhost:3000/api
测试Token: 在数据库中获取任意有效的device_token
```

### 14.2 Postman Collection

提供完整的Postman Collection，包含：
- 所有端点
- 示例请求
- 环境变量（Base URL, Device Token）

---

## 15. 文档和示例

### 15.1 OpenAPI/Swagger

生成OpenAPI 3.0规范文档：
- 端点定义
- 请求/响应Schema
- 认证方式
- 示例

### 15.2 SDK生成

基于OpenAPI文档，可生成：
- JavaScript/TypeScript SDK
- Swift SDK
- 其他语言SDK

---

**文档结束**
