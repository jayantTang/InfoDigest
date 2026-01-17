# InfoDigest v2.0 数据库设计

## 核心设计原则

1. **用户隔离**: 每个用户的数据完全隔离
2. **多资产类型**: 支持股票、ETF、指数、加密货币、商品、外汇
3. **配置持久化**: 用户配置同步到服务器
4. **历史可追溯**: 保留所有分析和推送历史
5. **高性能**: 分区表、索引优化、缓存友好

---

## 1. 用户和配置表

### 1.1 用户表 (users)
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE,
    device_id UUID,  -- 主设备ID
    push_enabled BOOLEAN DEFAULT true,
    push_token TEXT,  -- APNs device token

    -- 偏好设置
    preferences JSONB DEFAULT '{
        "analysis_length": "full",  -- full | summary
        "push_frequency": "normal",  -- minimal | normal | all
        "quiet_hours": {
            "enabled": false,
            "start": "22:00",
            "end": "08:00"
        },
        "risk_profile": "neutral",  -- conservative | neutral | aggressive
        "content_types": {
            "stocks": true,
            "crypto": true,
            "news": true,
            "technical": true,
            "fundamental": true
        }
    }'::jsonb,

    -- 学习到的画像（LLM分析用）
    learned_profile JSONB DEFAULT '{}',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_active_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_device_id ON users(device_id);
CREATE INDEX idx_users_push_token ON users(push_token) WHERE push_token IS NOT NULL;
```

### 1.2 持仓表 (portfolios)
```sql
CREATE TABLE portfolios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- 资产信息
    symbol VARCHAR(50) NOT NULL,
    asset_type VARCHAR(20) NOT NULL CHECK (asset_type IN ('stock', 'etf', 'index', 'crypto', 'commodity', 'forex')),
    exchange VARCHAR(50),  -- NASDAQ, NYSE, etc.

    -- 持仓详情
    shares DECIMAL(18, 8) NOT NULL,
    avg_cost DECIMAL(18, 4) NOT NULL,
    current_price DECIMAL(18, 4),
    unrealized_pnl DECIMAL(18, 2),
    total_value DECIMAL(18, 2),

    -- 交易信息
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- 监控设置
    alerts JSONB DEFAULT '{
        "price_above": null,
        "price_below": null,
        "percent_change": null,
        "volume_spike": false,
        "earnings": false
    }'::jsonb,

    -- 状态
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'closed', 'pending')),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(user_id, symbol)
);

CREATE INDEX idx_portfolios_user_id ON portfolios(user_id);
CREATE INDEX idx_portfolios_symbol ON portfolios(symbol);
CREATE INDEX idx_portfolios_asset_type ON portfolios(asset_type);
```

### 1.3 关注列表 (watchlists)
```sql
CREATE TABLE watchlists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- 资产信息
    symbol VARCHAR(50) NOT NULL,
    asset_type VARCHAR(20) NOT NULL,
    exchange VARCHAR(50),

    -- 关注原因
    reason VARCHAR(100) CHECK (reason IN ('potential_buy', 'competitor', 'sector_watch', 'speculative')),
    notes TEXT,

    -- 关注维度
    focus JSONB DEFAULT '{
        "price": true,
        "news": true,
        "technical": false,
        "sector": false
    }'::jsonb,

    -- 优先级
    priority INTEGER DEFAULT 5,  -- 1-10

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(user_id, symbol)
);

CREATE INDEX idx_watchlists_user_id ON watchlists(user_id);
CREATE INDEX idx_watchlists_symbol ON watchlists(symbol);
```

### 1.4 投资策略 (strategies)
```sql
CREATE TABLE strategies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- 策略信息
    name VARCHAR(200) NOT NULL,
    description TEXT,

    -- 触发条件
    symbol VARCHAR(50) NOT NULL,
    condition_type VARCHAR(50) NOT NULL,  -- price | technical | news | time
    conditions JSONB NOT NULL,  -- 灵活的条件配置

    -- 操作建议
    action JSONB NOT NULL,  -- 具体的操作建议
    reasoning TEXT,

    -- 策略状态
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed', 'cancelled')),
    priority INTEGER DEFAULT 5,  -- 1-10

    -- 触发历史
    last_triggered_at TIMESTAMP,
    trigger_count INTEGER DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_strategies_user_id ON strategies(user_id);
CREATE INDEX idx_strategies_symbol ON strategies(symbol);
CREATE INDEX idx_strategies_status ON strategies(status) WHERE status = 'active';
```

### 1.5 临时关注 (temporary_focus)
```sql
CREATE TABLE temporary_focus (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- 关注内容
    title VARCHAR(200) NOT NULL,
    description TEXT,

    -- 监控目标
    targets JSONB NOT NULL,  -- {symbols: [], keywords: [], timeframe: ""}

    -- 关注重点
    focus JSONB DEFAULT '{
        "news_impact": true,
        "price_reaction": false,
        "correlation": false,
        "sector_effect": false
    }'::jsonb,

    -- 过期时间
    expires_at TIMESTAMP NOT NULL,

    -- 状态
    status VARCHAR(20) DEFAULT 'monitoring' CHECK (status IN ('monitoring', 'completed', 'cancelled', 'extended')),

    -- 结果
    findings JSONB,  -- 监控到的发现

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_temporary_focus_user_id ON temporary_focus(user_id);
CREATE INDEX idx_temporary_focus_expires_at ON temporary_focus(expires_at);
CREATE INDEX idx_temporary_focus_status ON temporary_focus(status);
```

---

## 2. 市场数据表

### 2.1 资产主数据 (assets)
```sql
CREATE TABLE assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symbol VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200),
    asset_type VARCHAR(20) NOT NULL,
    exchange VARCHAR(50),
    country VARCHAR(10),
    currency VARCHAR(10) DEFAULT 'USD',

    -- 分类
    sector VARCHAR(100),
    industry VARCHAR(100),
    tags JSONB DEFAULT '[]'::jsonb,

    -- 元数据
    market_cap BIGINT,
    ipo_date DATE,
    website VARCHAR(500),

    -- 关联
    parent_symbol VARCHAR(50),  -- 母公司
    related_symbols JSONB DEFAULT '[]'::jsonb,

    -- 状态
    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_assets_symbol ON assets(symbol);
CREATE INDEX idx_assets_sector ON assets(sector);
CREATE INDEX idx_assets_tags ON assets USING gin(tags);
```

### 2.2 价格数据 (按月分区)
```sql
CREATE TABLE prices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symbol VARCHAR(50) NOT NULL,

    -- 价格
    open_price DECIMAL(18, 4),
    high_price DECIMAL(18, 4),
    low_price DECIMAL(18, 4),
    close_price DECIMAL(18, 4),

    -- 成交量
    volume BIGINT,
    turnover DECIMAL(18, 2),

    -- 时间戳
    timestamp TIMESTAMP NOT NULL,

    -- 数据质量
    is_estimated BOOLEAN DEFAULT false,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) PARTITION BY RANGE (timestamp);

-- 创建分区
CREATE TABLE prices_2025_01 PARTITION OF prices
FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE prices_2025_02 PARTITION OF prices
FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

-- 索引
CREATE INDEX idx_prices_symbol_timestamp ON prices(symbol, timestamp DESC);
CREATE INDEX idx_prices_timestamp ON prices(timestamp DESC);
```

### 2.3 技术指标缓存 (technical_indicators)
```sql
CREATE TABLE technical_indicators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symbol VARCHAR(50) NOT NULL,

    -- 计算时间
    calculated_at TIMESTAMP NOT NULL,

    -- 趋势指标
    sma_5 DECIMAL(18, 4),
    sma_10 DECIMAL(18, 4),
    sma_20 DECIMAL(18, 4),
    sma_50 DECIMAL(18, 4),
    ema_12 DECIMAL(18, 4),
    ema_26 DECIMAL(18, 4),

    -- 动量指标
    rsi DECIMAL(5, 2),
    macd DECIMAL(10, 4),
    macd_signal DECIMAL(10, 4),
    macd_histogram DECIMAL(10, 4),

    -- 波动率
    bollinger_upper DECIMAL(18, 4),
    bollinger_middle DECIMAL(18, 4),
    bollinger_lower DECIMAL(18, 4),
    atr DECIMAL(18, 4),

    -- 成交量
    volume_avg_5 BIGINT,
    volume_avg_20 BIGINT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_technical_symbol_date ON technical_indicators(symbol, calculated_at DESC);
```

### 2.4 板块数据 (sectors)
```sql
CREATE TABLE sectors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    name_en VARCHAR(100),

    -- 代表性ETF
    etf_symbol VARCHAR(50),

    -- 分类
    category VARCHAR(50),  -- technology, healthcare, finance...

    -- 描述
    description TEXT,

    -- 相关股票（动态）
    related_symbols JSONB DEFAULT '[]'::jsonb,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sector_performance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sector_id UUID REFERENCES sectors(id),
    date DATE NOT NULL,

    -- 表现
    return_percent DECIMAL(5, 2),

    -- 估值
    avg_pe DECIMAL(10, 2),
    pe_percentile INTEGER,  -- 历史分位数

    -- 资金流向
    net_inflow DECIMAL(18, 2),
    institutional_inflow DECIMAL(18, 2),

    -- 领涨股
    leaders JSONB DEFAULT '[]'::jsonb,

    -- 领跌股
    laggards JSONB DEFAULT '[]'::jsonb,

    -- 涨跌家数
    advancing_count INTEGER,
    declining_count INTEGER,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(sector_id, date)
);

CREATE INDEX idx_sector_performance_date ON sector_performance(date DESC);
```

### 2.5 新闻和事件 (news_events)
```sql
CREATE TABLE news_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- 基本信息
    title TEXT NOT NULL,
    description TEXT,
    source VARCHAR(100),
    url TEXT,

    -- 分类
    category VARCHAR(50) CHECK (category IN ('earnings', 'merger', 'product', 'regulation', 'macro', 'other')),
    importance_score INTEGER CHECK (importance_score BETWEEN 0 AND 100),

    -- 相关标的
    symbols JSONB DEFAULT '[]'::jsonb,
    sectors JSONB DEFAULT '[]'::jsonb,

    -- 时间
    published_at TIMESTAMP,
    fetched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- 状态
    is_processed BOOLEAN DEFAULT false,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_news_events_published_at ON news_events(published_at DESC);
CREATE INDEX idx_news_events_importance ON news_events(importance_score DESC);
CREATE INDEX idx_news_events_symbols ON news_events USING gin(symbols);
CREATE INDEX idx_news_events_processed ON news_events(is_processed) WHERE is_processed = false;
```

### 2.6 宏观经济数据 (macro_data)
```sql
CREATE TABLE macro_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- 指标信息
    indicator_code VARCHAR(50) NOT NULL,  -- GDP, CPI, UNEMPLOYMENT, FED_FUNDS_RATE
    indicator_name VARCHAR(200),
    country VARCHAR(10) DEFAULT 'US',

    -- 数据值
    value DECIMAL(18, 4),
    unit VARCHAR(50),  -- %, billions, etc.

    -- 时间
    period DATE NOT NULL,  -- 数据所属期间
    released_at TIMESTAMP,

    -- 元数据
    source VARCHAR(100),
    is_preliminary BOOLEAN DEFAULT false,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(indicator_code, period)
);

CREATE INDEX idx_macro_data_code_period ON macro_data(indicator_code, period DESC);
CREATE INDEX idx_macro_data_released_at ON macro_data(released_at DESC);
```

### 2.7 加密货币特有数据

#### 加密货币基础信息
```sql
CREATE TABLE crypto_assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symbol VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200),

    -- 分类
    crypto_sector VARCHAR(50) CHECK (crypto_sector IN ('layer1', 'layer2', 'defi', 'meme', 'ai', 'exchange', 'stablecoin', 'other')),
    market_cap_rank INTEGER,

    -- 供应量
    total_supply DECIMAL(18, 0),
    circulating_supply DECIMAL(18, 0),
    max_supply DECIMAL(18, 0),

    -- 官网信息
    website VARCHAR(500),
    whitepaper VARCHAR(500),
    twitter VARCHAR(200),
    telegram VARCHAR(200),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_crypto_assets_sector ON crypto_assets(crypto_sector);
CREATE INDEX idx_crypto_assets_rank ON crypto_assets(market_cap_rank);
```

#### 链上数据 (onchain_data)
```sql
CREATE TABLE onchain_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symbol VARCHAR(50) NOT NULL,

    -- 链上数据
    metric_type VARCHAR(50) NOT NULL,  -- whale_activity, exchange_flow, addresses, transactions
    metric_data JSONB NOT NULL,

    -- 计算时间
    calculated_at TIMESTAMP NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_onchain_symbol_type ON onchain_metrics(symbol, metric_type, calculated_at DESC);
```

#### 加密货币情绪 (crypto_sentiment)
```sql
CREATE TABLE crypto_sentiment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symbol VARCHAR(50) NOT NULL,

    -- 情绪指标
    fear_greed INTEGER CHECK (fear_greed BETWEEN 0 AND 100),
    social_mentions INTEGER,
    social_mentions_change DECIMAL(5, 2),

    -- 合约数据
    funding_rate DECIMAL(8, 6),
    open_interest BIGINT,
    long_short_ratio DECIMAL(5, 2),

    -- 时间
    measured_at TIMESTAMP NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_crypto_sentiment_symbol ON crypto_sentiment(symbol, measured_at DESC);
```

---

## 3. 分析和推送表

### 3.1 分析历史 (analyses)
```sql
CREATE TABLE analyses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- 分析类型
    analysis_type VARCHAR(50) NOT NULL,  -- hourly | immediate | query

    -- 分析内容（完整JSON）
    content JSONB NOT NULL,

    -- 摘要（用于推送）
    summary TEXT,

    -- 紧急程度
    urgency VARCHAR(20) DEFAULT 'normal' CHECK (urgency IN ('low', 'normal', 'high')),

    -- 相关标的
    symbols JSONB DEFAULT '[]'::jsonb,

    -- 推送状态
    push_sent_at TIMESTAMP,
    push_opened_at TIMESTAMP,

    -- 用户反馈
    user_feedback JSONB,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_analyses_user_id ON analyses(user_id, created_at DESC);
CREATE INDEX idx_analyses_symbols ON analyses USING gin(symbols);
CREATE INDEX idx_analyses_type ON analyses(analysis_type);
```

### 3.2 策略触发历史 (strategy_triggers)
```sql
CREATE TABLE strategy_triggers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    strategy_id UUID NOT NULL REFERENCES strategies(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- 触发信息
    triggered_at TIMESTAMP NOT NULL,
    trigger_reason TEXT,

    -- 市场状态
    market_data JSONB NOT NULL,

    -- 推送的内容
    analysis_id UUID REFERENCES analyses(id),

    -- 用户反馈
    user_action VARCHAR(50),  -- executed | not_executed | ignored
    user_feedback TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_strategy_triggers_strategy_id ON strategy_triggers(strategy_id, triggered_at DESC);
CREATE INDEX idx_strategy_triggers_user_id ON strategy_triggers(user_id, triggered_at DESC);
```

### 3.3 用户反馈 (user_feedback)
```sql
CREATE TABLE user_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- 反馈对象
    target_type VARCHAR(50) NOT NULL,  -- analysis | strategy | general
    target_id UUID,

    -- 反馈内容
    feedback_type VARCHAR(50) NOT NULL,  -- useful | not_useful | executed | not_executed
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    comments TEXT,

    -- 元数据
    metadata JSONB DEFAULT '{}',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_feedback_user_id ON user_feedback(user_id, created_at DESC);
CREATE INDEX idx_user_feedback_target ON user_feedback(target_type, target_id);
```

---

## 4. 系统和监控表

### 4.1 监控任务队列 (monitoring_tasks)
```sql
CREATE TABLE monitoring_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- 任务信息
    task_type VARCHAR(50) NOT NULL,  -- hourly_scan | immediate_trigger | user_query
    priority INTEGER DEFAULT 5,

    -- 任务数据
    payload JSONB NOT NULL,

    -- 状态
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),

    -- 时间
    scheduled_at TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,

    -- 结果
    result JSONB,
    error_message TEXT,

    -- 重试
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_monitoring_tasks_status ON monitoring_tasks(status, scheduled_at);
CREATE INDEX idx_monitoring_tasks_type ON monitoring_tasks(task_type, scheduled_at);
```

### 4.2 数据源状态 (data_source_status)
```sql
CREATE TABLE data_source_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_name VARCHAR(100) UNIQUE NOT NULL,
    source_type VARCHAR(50) NOT NULL,

    -- 状态
    is_active BOOLEAN DEFAULT true,
    last_fetch_at TIMESTAMP,
    last_error TEXT,
    error_count INTEGER DEFAULT 0,

    -- 配置
    config JSONB DEFAULT '{}',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_data_source_status_active ON data_source_status(is_active);
```

---

## 5. 初始化脚本

```sql
-- 插入初始板块数据
INSERT INTO sectors (name, name_en, etf_symbol, category) VALUES
('科技', 'Technology', 'XLK', 'technology'),
('半导体', 'Semiconductor', 'SOXX', 'technology'),
('金融', 'Finance', 'XLF', 'finance'),
('能源', 'Energy', 'XLE', 'energy'),
('医疗', 'Healthcare', 'XLV', 'healthcare'),
('消费', 'Consumer', 'XLY', 'consumer'),
('公用事业', 'Utilities', 'XLU', 'utilities'),
('房地产', 'Real Estate', 'XLRE', 'real_estate'),
('材料', 'Materials', 'XLB', 'materials'),
('工业', 'Industrials', 'XLI', 'industrials'),
('加密货币', 'Cryptocurrency', NULL, 'crypto'),
('AI概念', 'AI & Blockchain', NULL, 'technology');

-- 插入宏观经济指标
INSERT INTO macro_data (indicator_code, indicator_name, country, value, unit, period) VALUES
('GDP', 'Gross Domestic Product', 'US', 25.0, 'trillion', '2024-01-01'),
('CPI', 'Consumer Price Index', 'US', 3.2, '%', '2024-01-01'),
('UNEMPLOYMENT', 'Unemployment Rate', 'US', 3.7, '%', '2024-01-01'),
('FED_FUNDS_RATE', 'Federal Funds Rate', 'US', 5.25, '%', '2024-01-01');

-- 插入初始数据源状态
INSERT INTO data_source_status (source_name, source_type, is_active) VALUES
('Alpha Vantage', 'price', true),
('CoinGecko', 'crypto_price', true),
('NewsAPI', 'news', true),
('Financial Modeling Prep', 'fundamentals', true),
('Etherscan', 'onchain', true),
('FRED', 'macro', true);
```

---

## 6. 性能优化

### 分区表维护
```sql
-- 自动创建分区函数
CREATE OR REPLACE FUNCTION create_monthly_partition(table_name text, start_date date)
RETURNS void AS $$
DECLARE
    partition_name text;
    end_date date;
BEGIN
    partition_name := table_name || '_' || to_char(start_date, 'YYYY_MM');
    end_date := start_date + interval '1 month';

    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I PARTITION OF %I
        FOR VALUES FROM (%L) TO (%L)
    ', partition_name, table_name, start_date, end_date);
END;
$$ LANGUAGE plpgsql;

-- 每月自动创建下月分区
CREATE OR REPLACE PROCEDURE maintain_partitions()
LANGUAGE plpgsql
AS $$
BEGIN
    -- 为prices表创建未来3个月的分区
    FOR i IN 0..2 LOOP
        PERFORM create_monthly_partition('prices', date_trunc('month', CURRENT_DATE + (i || ' months')::interval));
    END LOOP;
END;
$$;
```

### 定期清理任务
```sql
-- 清理旧数据（保留2年）
DELETE FROM prices WHERE timestamp < CURRENT_DATE - INTERVAL '2 years';

-- 清理旧的分析（保留6个月）
DELETE FROM analyses WHERE created_at < CURRENT_DATE - INTERVAL '6 months';

-- 清理旧的监控任务（保留1个月）
DELETE FROM monitoring_tasks WHERE completed_at < CURRENT_DATE - INTERVAL '1 month';
```

---

## 7. 数据迁移计划

```sql
-- 从v1迁移到v2的步骤

-- 1. 备份现有数据
CREATE TABLE messages_backup AS SELECT * FROM messages;
CREATE TABLE devices_backup AS SELECT * FROM devices;

-- 2. 重命名旧表
ALTER TABLE messages RENAME TO messages_v1;
ALTER TABLE devices RENAME TO devices_v1;

-- 3. 创建新表结构
-- (执行上面的所有CREATE TABLE语句)

-- 4. 迁移用户数据
INSERT INTO users (email, device_id, push_token)
SELECT email, id, device_token FROM devices_v1
ON CONFLICT (email) DO NOTHING;

-- 5. 迁移消息到分析表
INSERT INTO analyses (user_id, analysis_type, content, summary, created_at)
SELECT (
    SELECT id FROM users LIMIT 1  -- 临时，实际需要映射
), 'historical',
jsonb_build_object(
    'title', title,
    'content', content_rich,
    'summary', summary
),
summary,
created_at
FROM messages_v1;

-- 6. 删除旧表
-- DROP TABLE messages_v1;
-- DROP TABLE devices_v1;
```

---

## 8. 使用示例

### 查询用户持仓和最新价格
```sql
SELECT
    p.symbol,
    p.shares,
    p.avg_cost,
    pr.close_price AS current_price,
    (p.shares * (pr.close_price - p.avg_cost)) AS unrealized_pnl
FROM portfolios p
LEFT JOIN LATERAL (
    SELECT close_price
    FROM prices
    WHERE symbol = p.symbol
    ORDER BY timestamp DESC
    LIMIT 1
) pr ON true
WHERE p.user_id = $1 AND p.status = 'active';
```

### 查询用户关注的标的今日表现
```sql
SELECT
    w.symbol,
    w.asset_type,
    a.name,
    pr.close_price,
    pr.change_percent,
    ti.rsi,
    ti.macd
FROM watchlists w
LEFT JOIN assets a ON w.symbol = a.symbol
LEFT JOIN LATERAL (
    SELECT
        close_price,
        round(((close_price - open_price) / open_price * 100), 2) AS change_percent
    FROM prices
    WHERE symbol = w.symbol
    AND date_trunc('day', timestamp) = date_trunc('day', CURRENT_DATE)
) pr ON true
LEFT JOIN LATERAL (
    SELECT rsi, macd
    FROM technical_indicators
    WHERE symbol = w.symbol
    ORDER BY calculated_at DESC
    LIMIT 1
) ti ON true
WHERE w.user_id = $1;
```

### 查询板块表现
```sql
SELECT
    s.name,
    sp.return_percent,
    sp.avg_pe,
    sp.pe_percentile,
    sp.net_inflow,
    sp.leaders,
    sp.laggards
FROM sector_performance sp
JOIN sectors s ON sp.sector_id = s.id
WHERE sp.date = CURRENT_DATE
ORDER BY sp.return_percent DESC;
```
