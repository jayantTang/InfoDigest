-- InfoDigest v2.0 初始化Schema
-- 执行方式: psql -h localhost -U huiminzhang -d infodigest -f 001_initial_schema_v2.sql

-- 启用UUID扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. 用户和配置表
-- ============================================

-- 1.1 用户表
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE,
    device_id UUID,
    push_enabled BOOLEAN DEFAULT true,
    push_token TEXT,

    -- 偏好设置
    preferences JSONB DEFAULT '{
        "analysis_length": "full",
        "push_frequency": "normal",
        "quiet_hours": {
            "enabled": false,
            "start": "22:00",
            "end": "08:00"
        },
        "risk_profile": "neutral",
        "content_types": {
            "stocks": true,
            "crypto": true,
            "news": true,
            "technical": true,
            "fundamental": true
        }
    }'::jsonb,

    -- 学习到的画像
    learned_profile JSONB DEFAULT '{}',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_active_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_device_id ON users(device_id);
CREATE INDEX IF NOT EXISTS idx_users_push_token ON users(push_token) WHERE push_token IS NOT NULL;

-- 1.2 持仓表
CREATE TABLE IF NOT EXISTS portfolios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    symbol VARCHAR(50) NOT NULL,
    asset_type VARCHAR(20) NOT NULL CHECK (asset_type IN ('stock', 'etf', 'index', 'crypto', 'commodity', 'forex')),
    exchange VARCHAR(50),

    shares DECIMAL(18, 8) NOT NULL,
    avg_cost DECIMAL(18, 4) NOT NULL,
    current_price DECIMAL(18, 4),
    unrealized_pnl DECIMAL(18, 2),
    total_value DECIMAL(18, 2),

    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    alerts JSONB DEFAULT '{
        "price_above": null,
        "price_below": null,
        "percent_change": null,
        "volume_spike": false,
        "earnings": false
    }'::jsonb,

    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'closed', 'pending')),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(user_id, symbol)
);

CREATE INDEX IF NOT EXISTS idx_portfolios_user_id ON portfolios(user_id);
CREATE INDEX IF NOT EXISTS idx_portfolios_symbol ON portfolios(symbol);
CREATE INDEX IF NOT EXISTS idx_portfolios_asset_type ON portfolios(asset_type);

-- 1.3 关注列表
CREATE TABLE IF NOT EXISTS watchlists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    symbol VARCHAR(50) NOT NULL,
    asset_type VARCHAR(20) NOT NULL,
    exchange VARCHAR(50),

    reason VARCHAR(100) CHECK (reason IN ('potential_buy', 'competitor', 'sector_watch', 'speculative')),
    notes TEXT,

    focus JSONB DEFAULT '{
        "price": true,
        "news": true,
        "technical": false,
        "sector": false
    }'::jsonb,

    priority INTEGER DEFAULT 5,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(user_id, symbol)
);

CREATE INDEX IF NOT EXISTS idx_watchlists_user_id ON watchlists(user_id);
CREATE INDEX IF NOT EXISTS idx_watchlists_symbol ON watchlists(symbol);

-- 1.4 投资策略
CREATE TABLE IF NOT EXISTS strategies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    name VARCHAR(200) NOT NULL,
    description TEXT,

    symbol VARCHAR(50) NOT NULL,
    condition_type VARCHAR(50) NOT NULL,
    conditions JSONB NOT NULL,

    action JSONB NOT NULL,
    reasoning TEXT,

    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed', 'cancelled')),
    priority INTEGER DEFAULT 5,

    last_triggered_at TIMESTAMP,
    trigger_count INTEGER DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_strategies_user_id ON strategies(user_id);
CREATE INDEX IF NOT EXISTS idx_strategies_symbol ON strategies(symbol);
CREATE INDEX IF NOT EXISTS idx_strategies_status ON strategies(status) WHERE status = 'active';

-- 1.5 临时关注
CREATE TABLE IF NOT EXISTS temporary_focus (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    title VARCHAR(200) NOT NULL,
    description TEXT,

    targets JSONB NOT NULL,
    focus JSONB DEFAULT '{
        "news_impact": true,
        "price_reaction": false,
        "correlation": false,
        "sector_effect": false
    }'::jsonb,

    expires_at TIMESTAMP NOT NULL,

    status VARCHAR(20) DEFAULT 'monitoring' CHECK (status IN ('monitoring', 'completed', 'cancelled', 'extended')),

    findings JSONB,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_temporary_focus_user_id ON temporary_focus(user_id);
CREATE INDEX IF NOT EXISTS idx_temporary_focus_expires_at ON temporary_focus(expires_at);
CREATE INDEX IF NOT EXISTS idx_temporary_focus_status ON temporary_focus(status);

-- ============================================
-- 2. 市场数据表
-- ============================================

-- 2.1 资产主数据
CREATE TABLE IF NOT EXISTS assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symbol VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200),
    asset_type VARCHAR(20) NOT NULL,
    exchange VARCHAR(50),
    country VARCHAR(10),
    currency VARCHAR(10) DEFAULT 'USD',

    sector VARCHAR(100),
    industry VARCHAR(100),
    tags JSONB DEFAULT '[]'::jsonb,

    market_cap BIGINT,
    ipo_date DATE,
    website VARCHAR(500),

    parent_symbol VARCHAR(50),
    related_symbols JSONB DEFAULT '[]'::jsonb,

    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_assets_symbol ON assets(symbol);
CREATE INDEX IF NOT EXISTS idx_assets_sector ON assets(sector);
CREATE INDEX IF NOT EXISTS idx_assets_tags ON assets USING gin(tags);

-- 2.2 价格数据表（按月分区）
CREATE TABLE IF NOT EXISTS prices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symbol VARCHAR(50) NOT NULL,

    open_price DECIMAL(18, 4),
    high_price DECIMAL(18, 4),
    low_price DECIMAL(18, 4),
    close_price DECIMAL(18, 4),

    volume BIGINT,
    turnover DECIMAL(18, 2),

    timestamp TIMESTAMP NOT NULL,

    is_estimated BOOLEAN DEFAULT false,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) PARTITION BY RANGE (timestamp);

-- 创建当月分区
DO $$
DECLARE
    current_month text := to_char(CURRENT_DATE, 'YYYY_MM');
    partition_name text := 'prices_' || current_month;
    start_date date := date_trunc('month', CURRENT_DATE);
    end_date date := start_date + interval '1 month';
BEGIN
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I PARTITION OF prices
        FOR VALUES FROM (%L) TO (%L)
    ', partition_name, start_date, end_date);
END $$;

-- 创建下月分区
DO $$
DECLARE
    next_month text := to_char(CURRENT_DATE + interval '1 month', 'YYYY_MM');
    partition_name text := 'prices_' || next_month;
    start_date date := date_trunc('month', CURRENT_DATE + interval '1 month');
    end_date date := start_date + interval '1 month';
BEGIN
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I PARTITION OF prices
        FOR VALUES FROM (%L) TO (%L)
    ', partition_name, start_date, end_date);
END $$;

CREATE INDEX IF NOT EXISTS idx_prices_symbol_timestamp ON prices(symbol, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_prices_timestamp ON prices(timestamp DESC);

-- 2.3 技术指标缓存
CREATE TABLE IF NOT EXISTS technical_indicators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symbol VARCHAR(50) NOT NULL,

    calculated_at TIMESTAMP NOT NULL,

    sma_5 DECIMAL(18, 4),
    sma_10 DECIMAL(18, 4),
    sma_20 DECIMAL(18, 4),
    sma_50 DECIMAL(18, 4),
    ema_12 DECIMAL(18, 4),
    ema_26 DECIMAL(18, 4),

    rsi DECIMAL(5, 2),
    macd DECIMAL(10, 4),
    macd_signal DECIMAL(10, 4),
    macd_histogram DECIMAL(10, 4),

    bollinger_upper DECIMAL(18, 4),
    bollinger_middle DECIMAL(18, 4),
    bollinger_lower DECIMAL(18, 4),
    atr DECIMAL(18, 4),

    volume_avg_5 BIGINT,
    volume_avg_20 BIGINT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_technical_symbol_date ON technical_indicators(symbol, calculated_at DESC);

-- 2.4 板块数据
CREATE TABLE IF NOT EXISTS sectors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    name_en VARCHAR(100),

    etf_symbol VARCHAR(50),
    category VARCHAR(50),

    description TEXT,

    related_symbols JSONB DEFAULT '[]'::jsonb,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sector_performance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sector_id UUID REFERENCES sectors(id),
    date DATE NOT NULL,

    return_percent DECIMAL(5, 2),

    avg_pe DECIMAL(10, 2),
    pe_percentile INTEGER,

    net_inflow DECIMAL(18, 2),
    institutional_inflow DECIMAL(18, 2),

    leaders JSONB DEFAULT '[]'::jsonb,
    laggards JSONB DEFAULT '[]'::jsonb,

    advancing_count INTEGER,
    declining_count INTEGER,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(sector_id, date)
);

CREATE INDEX IF NOT EXISTS idx_sector_performance_date ON sector_performance(date DESC);

-- 2.5 新闻和事件
CREATE TABLE IF NOT EXISTS news_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    title TEXT NOT NULL,
    description TEXT,
    source VARCHAR(100),
    url TEXT,

    category VARCHAR(50) CHECK (category IN ('earnings', 'merger', 'product', 'regulation', 'macro', 'other')),
    importance_score INTEGER CHECK (importance_score BETWEEN 0 AND 100),

    symbols JSONB DEFAULT '[]'::jsonb,
    sectors JSONB DEFAULT '[]'::jsonb,

    published_at TIMESTAMP,
    fetched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    is_processed BOOLEAN DEFAULT false,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_news_events_published_at ON news_events(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_news_events_importance ON news_events(importance_score DESC);
CREATE INDEX IF NOT EXISTS idx_news_events_symbols ON news_events USING gin(symbols);
CREATE INDEX IF NOT EXISTS idx_news_events_processed ON news_events(is_processed) WHERE is_processed = false;

-- 2.6 宏观经济数据
CREATE TABLE IF NOT EXISTS macro_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    indicator_code VARCHAR(50) NOT NULL,
    indicator_name VARCHAR(200),
    country VARCHAR(10) DEFAULT 'US',

    value DECIMAL(18, 4),
    unit VARCHAR(50),

    period DATE NOT NULL,
    released_at TIMESTAMP,

    source VARCHAR(100),
    is_preliminary BOOLEAN DEFAULT false,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(indicator_code, period)
);

CREATE INDEX IF NOT EXISTS idx_macro_data_code_period ON macro_data(indicator_code, period DESC);
CREATE INDEX IF NOT EXISTS idx_macro_data_released_at ON macro_data(released_at DESC);

-- 2.7 加密货币数据
CREATE TABLE IF NOT EXISTS crypto_assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symbol VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200),

    crypto_sector VARCHAR(50) CHECK (crypto_sector IN ('layer1', 'layer2', 'defi', 'meme', 'ai', 'exchange', 'stablecoin', 'other')),
    market_cap_rank INTEGER,

    total_supply DECIMAL(18, 0),
    circulating_supply DECIMAL(18, 0),
    max_supply DECIMAL(18, 0),

    website VARCHAR(500),
    whitepaper VARCHAR(500),
    twitter VARCHAR(200),
    telegram VARCHAR(200),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crypto_assets_sector ON crypto_assets(crypto_sector);
CREATE INDEX IF NOT EXISTS idx_crypto_assets_rank ON crypto_assets(market_cap_rank);

CREATE TABLE IF NOT EXISTS onchain_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symbol VARCHAR(50) NOT NULL,

    metric_type VARCHAR(50) NOT NULL,
    metric_data JSONB NOT NULL,

    calculated_at TIMESTAMP NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_onchain_symbol_type ON onchain_metrics(symbol, metric_type, calculated_at DESC);

CREATE TABLE IF NOT EXISTS crypto_sentiment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symbol VARCHAR(50) NOT NULL,

    fear_greed INTEGER CHECK (fear_greed BETWEEN 0 AND 100),
    social_mentions INTEGER,
    social_mentions_change DECIMAL(5, 2),

    funding_rate DECIMAL(8, 6),
    open_interest BIGINT,
    long_short_ratio DECIMAL(5, 2),

    measured_at TIMESTAMP NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crypto_sentiment_symbol ON crypto_sentiment(symbol, measured_at DESC);

-- ============================================
-- 3. 分析和推送表
-- ============================================

CREATE TABLE IF NOT EXISTS analyses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    analysis_type VARCHAR(50) NOT NULL,

    content JSONB NOT NULL,
    summary TEXT,

    urgency VARCHAR(20) DEFAULT 'normal' CHECK (urgency IN ('low', 'normal', 'high')),

    symbols JSONB DEFAULT '[]'::jsonb,

    push_sent_at TIMESTAMP,
    push_opened_at TIMESTAMP,

    user_feedback JSONB,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_analyses_user_id ON analyses(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analyses_symbols ON analyses USING gin(symbols);
CREATE INDEX IF NOT EXISTS idx_analyses_type ON analyses(analysis_type);

CREATE TABLE IF NOT EXISTS strategy_triggers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    strategy_id UUID NOT NULL REFERENCES strategies(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    triggered_at TIMESTAMP NOT NULL,
    trigger_reason TEXT,

    market_data JSONB NOT NULL,

    analysis_id UUID REFERENCES analyses(id),

    user_action VARCHAR(50),
    user_feedback TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_strategy_triggers_strategy_id ON strategy_triggers(strategy_id, triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_strategy_triggers_user_id ON strategy_triggers(user_id, triggered_at DESC);

CREATE TABLE IF NOT EXISTS user_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    target_type VARCHAR(50) NOT NULL,
    target_id UUID,

    feedback_type VARCHAR(50) NOT NULL,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    comments TEXT,

    metadata JSONB DEFAULT '{}',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_feedback_user_id ON user_feedback(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_feedback_target ON user_feedback(target_type, target_id);

-- ============================================
-- 4. 系统和监控表
-- ============================================

CREATE TABLE IF NOT EXISTS monitoring_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    task_type VARCHAR(50) NOT NULL,
    priority INTEGER DEFAULT 5,

    payload JSONB NOT NULL,

    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),

    scheduled_at TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,

    result JSONB,
    error_message TEXT,

    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_monitoring_tasks_status ON monitoring_tasks(status, scheduled_at);
CREATE INDEX IF NOT EXISTS idx_monitoring_tasks_type ON monitoring_tasks(task_type, scheduled_at);

CREATE TABLE IF NOT EXISTS data_source_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_name VARCHAR(100) UNIQUE NOT NULL,
    source_type VARCHAR(50) NOT NULL,

    is_active BOOLEAN DEFAULT true,
    last_fetch_at TIMESTAMP,
    last_error TEXT,
    error_count INTEGER DEFAULT 0,

    config JSONB DEFAULT '{}',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_data_source_status_active ON data_source_status(is_active);

-- ============================================
-- 5. 初始化数据
-- ============================================

-- 插入板块数据
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
('AI概念', 'AI & Blockchain', NULL, 'technology')
ON CONFLICT (name) DO NOTHING;

-- 插入宏观经济指标
INSERT INTO macro_data (indicator_code, indicator_name, country, value, unit, period, released_at) VALUES
('GDP', 'Gross Domestic Product', 'US', 25.0, 'trillion', '2024-01-01', '2024-01-25'),
('CPI', 'Consumer Price Index', 'US', 3.2, '%', '2024-01-01', '2024-02-01'),
('UNEMPLOYMENT', 'Unemployment Rate', 'US', 3.7, '%', '2024-01-01', '2024-02-02'),
('FED_FUNDS_RATE', 'Federal Funds Rate', 'US', 5.25, '%', '2024-01-01', '2024-01-31')
ON CONFLICT (indicator_code, period) DO NOTHING;

-- 插入数据源状态
INSERT INTO data_source_status (source_name, source_type, is_active, config) VALUES
('Alpha Vantage', 'price', true, '{"api_key": ""}'::jsonb),
('CoinGecko', 'crypto_price', true, '{"api_key": ""}'::jsonb),
('NewsAPI', 'news', true, '{"api_key": ""}'::jsonb),
('Financial Modeling Prep', 'fundamentals', true, '{"api_key": ""}'::jsonb),
('Etherscan', 'onchain', true, '{"api_key": ""}'::jsonb),
('FRED', 'macro', true, '{}'::jsonb)
ON CONFLICT (source_name) DO NOTHING;

-- ============================================
-- 6. 有用的函数和视图
-- ============================================

-- 自动更新updated_at字段的函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为需要的表添加触发器
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_portfolios_updated_at BEFORE UPDATE ON portfolios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_watchlists_updated_at BEFORE UPDATE ON watchlists
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_strategies_updated_at BEFORE UPDATE ON strategies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_temporary_focus_updated_at BEFORE UPDATE ON temporary_focus
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assets_updated_at BEFORE UPDATE ON assets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sectors_updated_at BEFORE UPDATE ON sectors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_crypto_assets_updated_at BEFORE UPDATE ON crypto_assets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_data_source_status_updated_at BEFORE UPDATE ON data_source_status
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 完成
-- ============================================

-- 输出创建完成信息
DO $$
BEGIN
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'InfoDigest v2.0 数据库Schema创建完成！';
    RAISE NOTICE '===========================================';
    RAISE NOTICE '创建的主要表：';
    RAISE NOTICE '- 用户配置: users, portfolios, watchlists, strategies, temporary_focus';
    RAISE NOTICE '- 市场数据: assets, prices, technical_indicators, sectors, news_events';
    RAISE NOTICE '- 加密货币: crypto_assets, onchain_metrics, crypto_sentiment';
    RAISE NOTICE '- 分析推送: analyses, strategy_triggers, user_feedback';
    RAISE NOTICE '- 系统监控: monitoring_tasks, data_source_status';
    RAISE NOTICE '===========================================';
END $$;
