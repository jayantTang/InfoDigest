/**
 * Type Definitions for InfoDigest v2.0
 * This file defines the structure of data objects used throughout the application
 *
 * Note: This is JSDoc-style type definitions for better IDE support.
 * For TypeScript projects, these would be interface definitions.
 */

/**
 * @typedef {Object} User
 * @property {string} id - User UUID
 * @property {string|null} email - User email
 * @property {string|null} device_id - Device UUID
 * @property {boolean} push_enabled - Push notification enabled
 * @property {string|null} push_token - APNs/FCM token
 * @property {UserPreferences} preferences - User preferences
 * @property {Object} learned_profile - System-learned user profile
 * @property {Date} created_at - Account creation time
 * @property {Date} updated_at - Last update time
 * @property {Date} last_active_at - Last activity time
 */

/**
 * @typedef {Object} UserPreferences
 * @property {string} analysis_length - 'full' or 'summary'
 * @property {string} push_frequency - 'minimal', 'normal', or 'all'
 * @property {QuietHours} quiet_hours - Quiet hours settings
 * @property {string} risk_profile - 'conservative', 'neutral', or 'aggressive'
 * @property {ContentTypes} content_types - Content type preferences
 */

/**
 * @typedef {Object} QuietHours
 * @property {boolean} enabled - Whether quiet hours are enabled
 * @property {string} start - Start time in HH:MM format
 * @property {string} end - End time in HH:MM format
 */

/**
 * @typedef {Object} ContentTypes
 * @property {boolean} stocks - Stock content enabled
 * @property {boolean} crypto - Crypto content enabled
 * @property {boolean} news - News content enabled
 * @property {boolean} technical - Technical analysis enabled
 * @property {boolean} fundamental - Fundamental analysis enabled
 */

/**
 * @typedef {Object} Portfolio
 * @property {string} id - Portfolio UUID
 * @property {string} user_id - User UUID
 * @property {string} symbol - Asset symbol (e.g., 'NVDA', 'BTC')
 * @property {AssetType} asset_type - Type of asset
 * @property {string|null} exchange - Exchange name
 * @property {number} shares - Number of shares/units
 * @property {number} avg_cost - Average cost per unit
 * @property {number|null} current_price - Current market price
 * @property {number|null} unrealized_pnl - Unrealized profit/loss
 * @property {number|null} total_value - Total position value
 * @property {Date} opened_at - Position open date
 * @property {Date} last_updated - Last update time
 * @property {PortfolioAlerts} alerts - Price/alert configuration
 * @property {PortfolioStatus} status - Position status
 * @property {Date} created_at - Creation time
 * @property {Date} updated_at - Last update time
 */

/**
 * @typedef {'stock'|'etf'|'index'|'crypto'|'commodity'|'forex'} AssetType
 */

/**
 * @typedef {Object} PortfolioAlerts
 * @property {number|null} price_above - Alert if price above this
 * @property {number|null} price_below - Alert if price below this
 * @property {number|null} percent_change - Alert if percent change exceeds this
 * @property {boolean} volume_spike - Alert on volume spike
 * @property {boolean} earnings - Alert on earnings
 */

/**
 * @typedef {'active'|'closed'|'pending'} PortfolioStatus
 */

/**
 * @typedef {Object} Watchlist
 * @property {string} id - Watchlist UUID
 * @property {string} user_id - User UUID
 * @property {string} symbol - Asset symbol
 * @property {AssetType} asset_type - Type of asset
 * @property {string|null} exchange - Exchange name
 * @property {WatchlistReason|null} reason - Reason for watching
 * @property {string|null} notes - User notes
 * @property {WatchlistFocus} focus - Focus areas
 * @property {number} priority - Priority 1-10 (1=lowest, 10=highest)
 * @property {Date} created_at - Creation time
 * @property {Date} updated_at - Last update time
 */

/**
 * @typedef {'potential_buy'|'competitor'|'sector_watch'|'speculative'} WatchlistReason
 */

/**
 * @typedef {Object} WatchlistFocus
 * @property {boolean} price - Watch price movements
 * @property {boolean} news - Watch news
 * @property {boolean} technical - Watch technical indicators
 * @property {boolean} sector - Watch sector performance
 */

/**
 * @typedef {Object} Strategy
 * @property {string} id - Strategy UUID
 * @property {string} user_id - User UUID
 * @property {string} name - Strategy name
 * @property {string|null} description - Strategy description
 * @property {string} symbol - Target symbol
 * @property {StrategyConditionType} condition_type - Type of trigger condition
 * @property {Object} conditions - Trigger conditions (depends on condition_type)
 * @property {StrategyAction} action - Action to take when triggered
 * @property {string|null} reasoning - Strategy reasoning
 * @property {StrategyStatus} status - Strategy status
 * @property {number} priority - Priority 1-10
 * @property {Date|null} last_triggered_at - Last trigger time
 * @property {number} trigger_count - Number of times triggered
 * @property {Date} created_at - Creation time
 * @property {Date} updated_at - Last update time
 */

/**
 * @typedef {'price'|'technical'|'news'|'time'|'portfolio_change'} StrategyConditionType
 */

/**
 * @typedef {Object} StrategyAction
 * @property {'buy'|'sell'|'hold'|'adjust'|'alert'} type - Action type
 * @property {number|null} amount - Quantity (for buy/sell)
 * @property {string} reason - Action reasoning
 * @property {Object|null} metadata - Additional metadata
 */

/**
 * @typedef {'active'|'paused'|'completed'|'cancelled'} StrategyStatus
 */

/**
 * @typedef {Object} TemporaryFocus
 * @property {string} id - Temporary focus UUID
 * @property {string} user_id - User UUID
 * @property {string} title - Focus title
 * @property {string|null} description - Focus description
 * @property {Array<Object>} targets - Target symbols/sectors
 * @property {TemporaryFocusFocus} focus - Focus areas
 * @property {Date} expires_at - Expiration time
 * @property {TemporaryFocusStatus} status - Status
 * @property {Object|null} findings - Analysis findings
 * @property {Date} created_at - Creation time
 * @property {Date} updated_at - Last update time
 */

/**
 * @typedef {Object} TemporaryFocusFocus
 * @property {boolean} news_impact - Monitor news impact
 * @property {boolean} price_reaction - Monitor price reaction
 * @property {boolean} correlation - Monitor correlations
 * @property {boolean} sector_effect - Monitor sector effects
 */

/**
 * @typedef {'monitoring'|'completed'|'cancelled'|'extended'} TemporaryFocusStatus
 */

/**
 * @typedef {Object} Asset
 * @property {string} id - Asset UUID
 * @property {string} symbol - Asset symbol
 * @property {string|null} name - Asset name
 * @property {AssetType} asset_type - Type of asset
 * @property {string|null} exchange - Exchange name
 * @property {string|null} country - Country code
 * @property {string} currency - Currency code
 * @property {string|null} sector - Sector name
 * @property {string|null} industry - Industry name
 * @property {Array<string>} tags - Asset tags
 * @property {number|null} market_cap - Market capitalization
 * @property {Date|null} ipo_date - IPO date
 * @property {string|null} website - Website URL
 * @property {string|null} parent_symbol - Parent symbol (for ETFs, etc.)
 * @property {Array<string>} related_symbols - Related symbols
 * @property {boolean} is_active - Whether asset is active
 * @property {Date} created_at - Creation time
 * @property {Date} updated_at - Last update time
 */

/**
 * @typedef {Object} Price
 * @property {string} id - Price UUID
 * @property {string} symbol - Asset symbol
 * @property {number|null} open_price - Open price
 * @property {number|null} high_price - High price
 * @property {number|null} low_price - Low price
 * @property {number|null} close_price - Close price
 * @property {number|null} volume - Trading volume
 * @property {number|null} turnover - Turnover amount
 * @property {Date} timestamp - Price timestamp
 * @property {boolean} is_estimated - Whether price is estimated
 * @property {Date} created_at - Creation time
 */

/**
 * @typedef {Object} TechnicalIndicator
 * @property {string} id - Indicator UUID
 * @property {string} symbol - Asset symbol
 * @property {Date} calculated_at - Calculation time
 * @property {number|null} sma_5 - 5-day SMA
 * @property {number|null} sma_10 - 10-day SMA
 * @property {number|null} sma_20 - 20-day SMA
 * @property {number|null} sma_50 - 50-day SMA
 * @property {number|null} ema_12 - 12-day EMA
 * @property {number|null} ema_26 - 26-day EMA
 * @property {number|null} rsi - RSI
 * @property {number|null} macd - MACD
 * @property {number|null} macd_signal - MACD signal
 * @property {number|null} macd_histogram - MACD histogram
 * @property {number|null} bollinger_upper - Upper Bollinger Band
 * @property {number|null} bollinger_middle - Middle Bollinger Band
 * @property {number|null} bollinger_lower - Lower Bollinger Band
 * @property {number|null} atr - Average True Range
 * @property {number|null} volume_avg_5 - 5-day average volume
 * @property {number|null} volume_avg_20 - 20-day average volume
 * @property {Date} created_at - Creation time
 */

/**
 * @typedef {Object} Analysis
 * @property {string} id - Analysis UUID
 * @property {string} user_id - User UUID
 * @property {string} analysis_type - Type of analysis
 * @property {Object} content - Analysis content (JSONB)
 * @property {string|null} summary - Summary text
 * @property {'low'|'normal'|'high'} urgency - Urgency level
 * @property {Array<string>} symbols - Related symbols
 * @property {Date|null} push_sent_at - Push sent time
 * @property {Date|null} push_opened_at - Push opened time
 * @property {Object|null} user_feedback - User feedback
 * @property {Date} created_at - Creation time
 */

/**
 * @typedef {Object} UserFeedback
 * @property {string} id - Feedback UUID
 * @property {string} user_id - User UUID
 * @property {string} target_type - Type of target (analysis, strategy, etc.)
 * @property {string|null} target_id - Target UUID
 * @property {string} feedback_type - Type of feedback
 * @property {number|null} rating - Rating 1-5
 * @property {string|null} comments - User comments
 * @property {Object} metadata - Additional metadata
 * @property {Date} created_at - Creation time
 */

/**
 * @typedef {Object} PaginatedResponse
 * @property {boolean} success - Success flag
 * @property {Object} data - Response data
 * @property {Array} data.items - Items array
 * @property {Object} meta - Metadata
 * @property {PaginationMeta} meta.pagination - Pagination info
 */

/**
 * @typedef {Object} PaginationMeta
 * @property {number} page - Current page
 * @property {number} limit - Items per page
 * @property {number} total - Total items
 * @property {number} totalPages - Total pages
 * @property {boolean} hasMore - Whether there are more pages
 */

/**
 * @typedef {Object} SuccessResponse
 * @property {boolean} success - Always true
 * @property {Object} data - Response data
 * @property {Object} [meta] - Optional metadata
 */

/**
 * @typedef {Object} ErrorResponse
 * @property {boolean} success - Always false
 * @property {string} error - Error message
 * @property {string} [errorCode] - Optional error code
 */

export default {
  // This file is for type documentation only
  // In TypeScript, these would be exported interfaces
};
