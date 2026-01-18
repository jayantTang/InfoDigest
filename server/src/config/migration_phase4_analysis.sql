-- Migration for Phase 4: LLM Analysis Tables
-- This migration adds tables to store AI-generated analyses

-- Strategy Analyses Table
-- Stores LLM-generated analyses for triggered strategies
CREATE TABLE IF NOT EXISTS strategy_analyses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    strategy_id UUID NOT NULL REFERENCES strategies(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Analysis content
    title VARCHAR(200) NOT NULL,
    trigger_reason TEXT,
    market_context TEXT,
    technical_analysis TEXT,
    risk_assessment VARCHAR(50),
    action_suggestion TEXT,

    -- Confidence score (0-100)
    confidence INTEGER CHECK (confidence BETWEEN 0 AND 100),

    -- Raw JSON data from LLM
    analysis_data JSONB DEFAULT '{}'::jsonb,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Indexes for efficient queries
    CONSTRAINT strategy_analyses_unique_trigger UNIQUE (strategy_id, created_at)
);

CREATE INDEX idx_strategy_analyses_strategy_id ON strategy_analyses(strategy_id);
CREATE INDEX idx_strategy_analyses_user_id ON strategy_analyses(user_id);
CREATE INDEX idx_strategy_analyses_created_at ON strategy_analyses(created_at DESC);


-- Focus Analyses Table
-- Stores LLM-generated summaries for temporary focus items
CREATE TABLE IF NOT EXISTS focus_analyses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    focus_item_id UUID NOT NULL REFERENCES temporary_focus(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Analysis content
    title VARCHAR(200) NOT NULL,
    summary TEXT,
    key_findings JSONB DEFAULT '[]'::jsonb,
    price_analysis TEXT,
    correlation_analysis TEXT,
    action_suggestions JSONB DEFAULT '[]'::jsonb,

    -- Risk assessment
    risk_level VARCHAR(20) CHECK (risk_level IN ('low', 'medium', 'high')),

    -- Confidence score (0-100)
    confidence INTEGER CHECK (confidence BETWEEN 0 AND 100),

    -- Raw JSON data from LLM
    analysis_data JSONB DEFAULT '{}'::jsonb,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Indexes for efficient queries
    CONSTRAINT focus_analyses_unique_item UNIQUE (focus_item_id, created_at)
);

CREATE INDEX idx_focus_analyses_focus_item_id ON focus_analyses(focus_item_id);
CREATE INDEX idx_focus_analyses_user_id ON focus_analyses(user_id);
CREATE INDEX idx_focus_analyses_created_at ON focus_analyses(created_at DESC);


-- Event Analyses Table
-- Stores LLM-generated analyses for market events
CREATE TABLE IF NOT EXISTS event_analyses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES news_events(id) ON DELETE CASCADE,

    -- Analysis content
    title VARCHAR(200) NOT NULL,
    event_summary TEXT,
    impact_analysis TEXT,
    affected_assets JSONB DEFAULT '[]'::jsonb,
    market_reaction TEXT,
    future_outlook TEXT,
    key_takeaways JSONB DEFAULT '[]'::jsonb,

    -- Severity assessment
    severity VARCHAR(20) CHECK (severity IN ('low', 'medium', 'high')),

    -- Confidence score (0-100)
    confidence INTEGER CHECK (confidence BETWEEN 0 AND 100),

    -- Raw JSON data from LLM
    analysis_data JSONB DEFAULT '{}'::jsonb,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Indexes for efficient queries
    CONSTRAINT event_analyses_unique_event UNIQUE (event_id, created_at)
);

CREATE INDEX idx_event_analyses_event_id ON event_analyses(event_id);
CREATE INDEX idx_event_analyses_created_at ON event_analyses(created_at DESC);


-- Update strategy_triggers table to include analysis reference
-- This links each trigger to its analysis
ALTER TABLE strategy_triggers
ADD COLUMN IF NOT EXISTS analysis_id UUID REFERENCES strategy_analyses(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_strategy_triggers_analysis_id ON strategy_triggers(analysis_id);


-- Update temporary_focus table to include analysis reference
ALTER TABLE temporary_focus
ADD COLUMN IF NOT EXISTS analysis_id UUID REFERENCES focus_analyses(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_temporary_focus_analysis_id ON temporary_focus(analysis_id);


-- Update news_events table to include analysis reference
ALTER TABLE news_events
ADD COLUMN IF NOT EXISTS analysis_id UUID REFERENCES event_analyses(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_news_events_analysis_id ON news_events(analysis_id);
