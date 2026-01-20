/**
 * Monitoring Engine for v2.0
 * Monitors strategies, temporary focus items, and market events
 * Triggers actions when conditions are met
 */

import logger from '../config/logger.js';
import { pool } from '../config/database.js';
import pushNotificationQueue from './pushNotificationQueue.js';
import eventScoringEngine from './eventScoringEngine.js';
import llmAnalysisService from './llmAnalysisService.js';

class MonitoringEngine {
  constructor() {
    this.isRunning = false;
    this.checkInterval = 60000; // Check every minute
    this.intervalId = null;
  }

  /**
   * Start the monitoring engine
   */
  async start() {
    if (this.isRunning) {
      logger.warn('Monitoring engine already running');
      return;
    }

    logger.info('Starting monitoring engine');

    this.isRunning = true;

    // Run initial check
    await this.runMonitoringCycle();

    // Schedule periodic checks
    this.intervalId = setInterval(async () => {
      try {
        await this.runMonitoringCycle();
      } catch (error) {
        logger.error('Monitoring cycle failed', {
          error: error.message,
          stack: error.stack,
        });
      }
    }, this.checkInterval);

    logger.info('Monitoring engine started', {
      checkInterval: this.checkInterval,
    });
  }

  /**
   * Stop the monitoring engine
   */
  stop() {
    if (!this.isRunning) {
      logger.warn('Monitoring engine not running');
      return;
    }

    logger.info('Stopping monitoring engine');

    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }

    this.isRunning = false;

    logger.info('Monitoring engine stopped');
  }

  /**
   * Run a complete monitoring cycle
   */
  async runMonitoringCycle() {
    const startTime = Date.now();

    logger.info('Starting monitoring cycle');

    try {
      // 1. Check active strategies
      const strategyResults = await this.checkStrategies();

      // 2. Check temporary focus items
      const focusResults = await this.checkTemporaryFocus();

      // 3. Check for important market events
      const eventResults = await this.checkMarketEvents();

      // 4. Update monitoring tasks status
      await this.cleanupExpiredTasks();

      const duration = Date.now() - startTime;

      logger.info('Monitoring cycle completed', {
        duration,
        strategiesTriggered: strategyResults.triggered,
        focusItemsChecked: focusResults.checked,
        eventsFound: eventResults.found,
      });
    } catch (error) {
      logger.error('Monitoring cycle error', {
        error: error.message,
        stack: error.stack,
      });
      throw error;
    }
  }

  /**
   * Check all active strategies for triggers
   */
  async checkStrategies() {
    try {
      const query = `
        SELECT
          s.id,
          s.user_id,
          s.symbol,
          s.condition_type,
          s.conditions,
          s.action,
          s.priority
        FROM strategies s
        JOIN users u ON s.user_id = u.id
        WHERE s.status = 'active'
        ORDER BY s.priority DESC
      `;

      const result = await pool.query(query);
      const strategies = result.rows;

      logger.debug(`Checking ${strategies.length} active strategies`);

      let triggeredCount = 0;

      for (const strategy of strategies) {
        try {
          const shouldTrigger = await this.evaluateStrategy(strategy);

          if (shouldTrigger) {
            await this.triggerStrategy(strategy);
            triggeredCount++;
          }
        } catch (error) {
          logger.error(`Failed to evaluate strategy ${strategy.id}`, {
            error: error.message,
          });
        }
      }

      return {
        checked: strategies.length,
        triggered: triggeredCount,
      };
    } catch (error) {
      logger.error('Failed to check strategies', {
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Evaluate if a strategy should trigger
   * @param {Object} strategy - Strategy object
   */
  async evaluateStrategy(strategy) {
    const { symbol, condition_type, conditions } = strategy;

    try {
      switch (condition_type) {
        case 'price':
          return await this.evaluatePriceCondition(symbol, conditions);

        case 'technical':
          return await this.evaluateTechnicalCondition(symbol, conditions);

        case 'news':
          return await this.evaluateNewsCondition(symbol, conditions);

        case 'time':
          return this.evaluateTimeCondition(conditions);

        default:
          logger.warn(`Unknown condition type: ${condition_type}`);
          return false;
      }
    } catch (error) {
      logger.error(`Failed to evaluate strategy ${strategy.id}`, {
        error: error.message,
      });
      return false;
    }
  }

  /**
   * Evaluate price-based condition
   */
  async evaluatePriceCondition(symbol, conditions) {
    try {
      // Get latest price
      const priceResult = await pool.query(
        'SELECT close_price FROM prices WHERE symbol = $1 ORDER BY timestamp DESC LIMIT 1',
        [symbol]
      );

      if (priceResult.rows.length === 0) {
        return false;
      }

      const currentPrice = priceResult.rows[0].close_price;

      // Check conditions
      if (conditions.priceAbove && currentPrice > conditions.priceAbove) {
        return true;
      }

      if (conditions.priceBelow && currentPrice < conditions.priceBelow) {
        return true;
      }

      if (conditions.percentChange) {
        // Get previous price for comparison
        const prevResult = await pool.query(
          'SELECT close_price FROM prices WHERE symbol = $1 ORDER BY timestamp DESC LIMIT 2 OFFSET 1',
          [symbol]
        );

        if (prevResult.rows.length > 0) {
          const prevPrice = prevResult.rows[0].close_price;
          const change = ((currentPrice - prevPrice) / prevPrice) * 100;

          if (Math.abs(change) >= Math.abs(conditions.percentChange)) {
            return true;
          }
        }
      }

      return false;
    } catch (error) {
      logger.error('Failed to evaluate price condition', {
        error: error.message,
        symbol,
      });
      return false;
    }
  }

  /**
   * Evaluate technical indicator condition
   */
  async evaluateTechnicalCondition(symbol, conditions) {
    try {
      // Get latest technical indicators
      const techResult = await pool.query(
        'SELECT * FROM technical_indicators WHERE symbol = $1 ORDER BY calculated_at DESC LIMIT 1',
        [symbol]
      );

      if (techResult.rows.length === 0) {
        return false;
      }

      const indicators = techResult.rows[0];

      // Check RSI conditions
      if (conditions.rsi) {
        if (conditions.rsi.above && indicators.rsi > conditions.rsi.above) {
          return true;
        }
        if (conditions.rsi.below && indicators.rsi < conditions.rsi.below) {
          return true;
        }
      }

      // Check MACD conditions
      if (conditions.macd && indicators.macd_histogram) {
        if (conditions.macd.crossoverAbove && indicators.macd_histogram > 0) {
          return true;
        }
        if (conditions.macd.crossoverBelow && indicators.macd_histogram < 0) {
          return true;
        }
      }

      // Check Bollinger Bands
      if (conditions.bollinger) {
        if (conditions.bollinger.touchUpper && indicators.bollinger_upper) {
          const price = await this.getCurrentPrice(symbol);
          return price >= indicators.bollinger_upper * 0.99;
        }
        if (conditions.bollinger.touchLower && indicators.bollinger_lower) {
          const price = await this.getCurrentPrice(symbol);
          return price <= indicators.bollinger_lower * 1.01;
        }
      }

      return false;
    } catch (error) {
      logger.error('Failed to evaluate technical condition', {
        error: error.message,
        symbol,
      });
      return false;
    }
  }

  /**
   * Evaluate news-based condition
   */
  async evaluateNewsCondition(symbol, conditions) {
    try {
      // Get recent news for the symbol
      const newsResult = await pool.query(
        `SELECT importance_score, category, published_at
         FROM news_events
         WHERE $1 = ANY(symbols)
           AND published_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
         ORDER BY importance_score DESC
         LIMIT 10`,
        [symbol]
      );

      if (newsResult.rows.length === 0) {
        return false;
      }

      // Check if there's important news
      for (const news of newsResult.rows) {
        if (conditions.minImportance && news.importance_score >= conditions.minImportance) {
          return true;
        }

        if (conditions.categories && conditions.categories.includes(news.category)) {
          return true;
        }
      }

      return false;
    } catch (error) {
      logger.error('Failed to evaluate news condition', {
        error: error.message,
        symbol,
      });
      return false;
    }
  }

  /**
   * Evaluate time-based condition
   */
  evaluateTimeCondition(conditions) {
    const now = new Date();
    const currentTime = now.getHours() * 60 + now.getMinutes();

    if (conditions.timeRange) {
      const [startHour, startMin] = conditions.timeRange.start.split(':').map(Number);
      const [endHour, endMin] = conditions.timeRange.end.split(':').map(Number);

      const startTime = startHour * 60 + startMin;
      const endTime = endHour * 60 + endMin;

      return currentTime >= startTime && currentTime <= endTime;
    }

    if (conditions.dayOfWeek !== undefined) {
      const dayOfWeek = now.getDay();
      return dayOfWeek === conditions.dayOfWeek;
    }

    return false;
  }

  /**
   * Trigger a strategy
   */
  async triggerStrategy(strategy) {
    try {
      logger.info('Triggering strategy', {
        strategyId: strategy.id,
        symbol: strategy.symbol,
      });

      // Create trigger record
      const marketData = await this.getMarketData(strategy.symbol);

      // Generate trigger reason
      const triggerReason = this.generateTriggerReason(strategy, marketData);

      // Generate LLM analysis (async, don't wait)
      this.generateStrategyAnalysisAsync(strategy, marketData, triggerReason);

      // Record strategy trigger
      await this.recordStrategyTrigger(strategy, marketData, triggerReason);

      // Send push notification (will include analysis if ready)
      await this.sendStrategyPush(strategy, marketData, triggerReason);

      logger.info('Strategy triggered successfully', {
        strategyId: strategy.id,
      });
    } catch (error) {
      logger.error('Failed to trigger strategy', {
        error: error.message,
        strategyId: strategy.id,
      });
      throw error;
    }
  }

  /**
   * Generate trigger reason description
   */
  generateTriggerReason(strategy, marketData) {
    const { condition_type, conditions } = strategy;
    const price = marketData.price;

    switch (condition_type) {
      case 'price':
        if (conditions.priceAbove && price) {
          return `价格突破 $${conditions.priceAbove}，当前价格 $${price.close_price?.toFixed(2)}`;
        } else if (conditions.priceBelow && price) {
          return `价格跌破 $${conditions.priceBelow}，当前价格 $${price.close_price?.toFixed(2)}`;
        } else if (conditions.percentChange && price) {
          const direction = price.change_percent >= 0 ? '上涨' : '下跌';
          return `价格${direction} ${Math.abs(price.change_percent)?.toFixed(2)}%，超过阈值 ${conditions.percentChange}%`;
        }
        break;

      case 'technical':
        if (conditions.rsi && marketData.technical) {
          const rsi = marketData.technical.rsi;
          if (conditions.rsi.above && rsi > conditions.rsi.above) {
            return `RSI (${rsi.toFixed(1)}) 超过 ${conditions.rsi.above}`;
          } else if (conditions.rsi.below && rsi < conditions.rsi.below) {
            return `RSI (${rsi.toFixed(1)}) 低于 ${conditions.rsi.below}`;
          }
        }
        if (conditions.macd && marketData.technical?.macd_histogram) {
          const macd = marketData.technical.macd_histogram;
          return `MACD柱状图 (${macd.toFixed(4)}) 触发信号`;
        }
        return '技术指标条件满足';
        break;

      case 'news':
        return '检测到重要新闻事件';
        break;

      case 'time':
        if (conditions.timeRange) {
          return `当前时间在 ${conditions.timeRange.start}-${conditions.timeRange.end} 范围内`;
        }
        return '时间条件满足';
        break;

      default:
        return '策略条件触发';
    }

    return '策略条件满足';
  }

  /**
   * Generate strategy analysis asynchronously
   */
  async generateStrategyAnalysisAsync(strategy, marketData, triggerReason) {
    try {
      logger.info('Generating async strategy analysis', {
        strategyId: strategy.id,
      });

      const analysis = await llmAnalysisService.generateStrategyAnalysis(
        strategy,
        marketData,
        triggerReason
      );

      logger.info('Async strategy analysis completed', {
        strategyId: strategy.id,
        analysisTitle: analysis.title,
      });

      return analysis;
    } catch (error) {
      logger.error('Failed to generate async strategy analysis', {
        error: error.message,
        strategyId: strategy.id,
      });
      // Don't throw - analysis is optional
      return null;
    }
  }

  /**
   * Record strategy trigger
   */
  async recordStrategyTrigger(strategy, marketData, triggerReason) {
    try {
      const query = `
        INSERT INTO strategy_triggers (
          strategy_id, user_id, triggered_at, trigger_reason, market_data
        ) VALUES ($1, $2, CURRENT_TIMESTAMP, $3, $4)
      `;

      await pool.query(query, [
        strategy.id,
        strategy.user_id,
        triggerReason,
        JSON.stringify(marketData),
      ]);

      // Update strategy trigger count
      await pool.query(
        'UPDATE strategies SET last_triggered_at = CURRENT_TIMESTAMP, trigger_count = trigger_count + 1 WHERE id = $1',
        [strategy.id]
      );
    } catch (error) {
      logger.error('Failed to record strategy trigger', {
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Get current price for symbol
   */
  async getCurrentPrice(symbol) {
    try {
      const result = await pool.query(
        'SELECT close_price FROM prices WHERE symbol = $1 ORDER BY timestamp DESC LIMIT 1',
        [symbol]
      );

      return result.rows.length > 0 ? result.rows[0].close_price : null;
    } catch (error) {
      logger.error('Failed to get current price', {
        error: error.message,
        symbol,
      });
      return null;
    }
  }

  /**
   * Get market data for a symbol
   */
  async getMarketData(symbol) {
    try {
      const [priceResult, techResult] = await Promise.all([
        pool.query('SELECT * FROM prices WHERE symbol = $1 ORDER BY timestamp DESC LIMIT 1', [symbol]),
        pool.query('SELECT * FROM technical_indicators WHERE symbol = $1 ORDER BY calculated_at DESC LIMIT 1', [symbol]),
      ]);

      return {
        price: priceResult.rows[0] || null,
        technical: techResult.rows[0] || null,
        timestamp: new Date(),
      };
    } catch (error) {
      logger.error('Failed to get market data', {
        error: error.message,
        symbol,
      });
      return {};
    }
  }

  /**
   * Check temporary focus items
   */
  async checkTemporaryFocus() {
    try {
      const query = `
        SELECT
          tf.id,
          tf.user_id,
          tf.title,
          tf.targets,
          tf.focus,
          tf.expires_at
        FROM temporary_focus tf
        WHERE tf.status = 'monitoring'
        ORDER BY tf.created_at DESC
      `;

      const result = await pool.query(query);
      const focusItems = result.rows;

      logger.debug(`Checking ${focusItems.length} temporary focus items`);

      // Check each focus item
      for (const item of focusItems) {
        try {
          await this.checkFocusItem(item);
        } catch (error) {
          logger.error(`Failed to check focus item ${item.id}`, {
            error: error.message,
          });
        }
      }

      return {
        checked: focusItems.length,
      };
    } catch (error) {
      logger.error('Failed to check temporary focus', {
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Check a single temporary focus item
   */
  async checkFocusItem(focusItem) {
    try {
      logger.debug(`Checking focus item: ${focusItem.title}`);

      const { targets, focus, expires_at } = focusItem;

      // Parse JSON fields if needed
      const targetSymbols = typeof targets === 'string' ? JSON.parse(targets) : targets;
      const focusPoints = typeof focus === 'string' ? JSON.parse(focus) : focus;

      // Check each target symbol
      for (const symbol of targetSymbols) {
        try {
          // Get market data
          const marketData = await this.getMarketData(symbol);

          // Get recent news
          const newsResult = await pool.query(
            `SELECT * FROM news_events
             WHERE $1 = ANY(symbols)
               AND published_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
             ORDER BY importance_score DESC
             LIMIT 5`,
            [symbol]
          );

          // Check for significant price movement
          if (marketData.price && marketData.price.change_percent) {
            const changeAbs = Math.abs(marketData.price.change_percent);

            // Alert on significant moves (>3%)
            if (changeAbs > 3) {
              await this.sendFocusAlert(focusItem, symbol, marketData, 'price_movement');
            }
          }

          // Check for important news
          if (newsResult.rows.length > 0) {
            const importantNews = newsResult.rows.filter((n) => n.importance_score >= 70);

            if (importantNews.length > 0) {
              await this.sendFocusAlert(focusItem, symbol, marketData, 'news', importantNews[0]);
            }
          }

          // Check focus points
          for (const focusPoint of focusPoints) {
            if (focusPoint.type === 'price_level') {
              await this.checkPriceFocusPoint(focusItem, symbol, focusPoint, marketData);
            } else if (focusPoint.type === 'correlation') {
              await this.checkCorrelationFocusPoint(focusItem, symbol, focusPoint);
            }
          }
        } catch (error) {
          logger.error(`Failed to check symbol ${symbol} for focus item ${focusItem.id}`, {
            error: error.message,
          });
        }
      }

      // Check if expired
      if (new Date(expires_at) < new Date()) {
        await this.markFocusItemExpired(focusItem.id);
      }
    } catch (error) {
      logger.error(`Failed to check focus item ${focusItem.id}`, {
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Check price focus point
   */
  async checkPriceFocusPoint(focusItem, symbol, focusPoint, marketData) {
    if (!marketData.price || !focusPoint.price) {
      return;
    }

    const currentPrice = marketData.price.close_price;
    const targetPrice = focusPoint.price;
    const threshold = focusPoint.threshold || 0.02; // 2% default threshold

    // Check if price is within threshold of target
    const priceDiff = Math.abs(currentPrice - targetPrice) / targetPrice;

    if (priceDiff <= threshold) {
      logger.info(`Price focus point reached for ${symbol}`, {
        targetPrice,
        currentPrice,
        focusItemId: focusItem.id,
      });

      await this.sendFocusAlert(focusItem, symbol, marketData, 'price_focus_point', {
        targetPrice,
        currentPrice,
        threshold,
      });
    }
  }

  /**
   * Check correlation focus point
   */
  async checkCorrelationFocusPoint(focusItem, symbol, focusPoint) {
    // TODO: Implement correlation analysis
    // This would check if multiple symbols are moving together
    logger.debug(`Correlation check not yet implemented for ${symbol}`);
  }

  /**
   * Send focus alert notification
   */
  async sendFocusAlert(focusItem, symbol, marketData, alertType, alertData = null) {
    try {
      let title = '';
      let message = '';
      let priority = 60;

      switch (alertType) {
        case 'price_movement':
          const change = marketData.price?.change_percent;
          const direction = change >= 0 ? '上涨' : '下跌';
          title = `临时关注异动: ${symbol}`;
          message = `${symbol} ${direction} ${Math.abs(change)?.toFixed(2)}%，当前价格 $${marketData.price?.close_price?.toFixed(2)}`;
          priority = Math.abs(change) > 5 ? 90 : 70;
          break;

        case 'news':
          title = `临时关注新闻: ${symbol}`;
          const news = alertData;
          message = `${symbol}: ${news.title}`;
          priority = news.importance_score + 10;
          break;

        case 'price_focus_point':
          title = `关注价位到达: ${symbol}`;
          message = `${symbol} 接近目标价位 $${alertData.targetPrice?.toFixed(2)}，当前价格 $${alertData.currentPrice?.toFixed(2)}`;
          priority = 75;
          break;

        default:
          title = `临时关注更新: ${symbol}`;
          message = `${symbol} 有新动态`;
      }

      // Enqueue push notification
      const result = await pushNotificationQueue.enqueue({
        userId: focusItem.user_id,
        title,
        message,
        priority,
        type: 'focus_alert',
        data: {
          focusItemId: focusItem.id,
          focusTitle: focusItem.title,
          symbol,
          alertType,
          alertData,
          marketData: {
            price: marketData.price?.close_price,
            change: marketData.price?.change_percent,
          },
        },
      });

      if (result.success) {
        logger.info('Focus alert notification queued', {
          focusItemId: focusItem.id,
          symbol,
          alertType,
          notificationId: result.notificationId,
          priority,
        });
      }
    } catch (error) {
      logger.error('Failed to send focus alert', {
        error: error.message,
        focusItemId: focusItem.id,
        symbol,
      });
      throw error;
    }
  }

  /**
   * Mark focus item as expired
   */
  async markFocusItemExpired(focusItemId) {
    try {
      await pool.query(
        'UPDATE temporary_focus SET status = $1, completed_at = CURRENT_TIMESTAMP WHERE id = $2',
        ['expired', focusItemId]
      );

      logger.info(`Focus item marked as expired: ${focusItemId}`);
    } catch (error) {
      logger.error('Failed to mark focus item as expired', {
        error: error.message,
        focusItemId,
      });
      throw error;
    }
  }

  /**
   * Check for important market events
   */
  async checkMarketEvents() {
    try {
      // Get recent high-importance news
      const query = `
        SELECT
          id,
          title,
          symbols,
          sectors,
          importance_score,
          published_at
        FROM news_events
        WHERE importance_score >= 80
          AND is_processed = false
        ORDER BY importance_score DESC
        LIMIT 10
      `;

      const result = await pool.query(query);
      const events = result.rows;

      logger.debug(`Found ${events.length} high-importance events`);

      // Process each event
      for (const event of events) {
        try {
          await this.processMarketEvent(event);
        } catch (error) {
          logger.error(`Failed to process event ${event.id}`, {
            error: error.message,
          });
        }
      }

      return {
        found: events.length,
      };
    } catch (error) {
      logger.error('Failed to check market events', {
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Process a market event
   */
  async processMarketEvent(event) {
    try {
      logger.info(`Processing market event: ${event.title}`, {
        eventId: event.id,
        importanceScore: event.importance_score,
        symbols: event.symbols,
      });

      // Find relevant users based on symbols and sectors
      const relevantUsers = await this.findRelevantUsers(event);

      if (relevantUsers.length === 0) {
        logger.info('No relevant users found for event', { eventId: event.id });
        await this.markEventProcessed(event.id);
        return;
      }

      logger.info(`Found ${relevantUsers.length} relevant users for event`, {
        eventId: event.id,
      });

      // Send notifications to relevant users
      for (const user of relevantUsers) {
        try {
          await this.sendEventNotification(user, event);
        } catch (error) {
          logger.error(`Failed to send event notification to user ${user.user_id}`, {
            error: error.message,
            eventId: event.id,
          });
        }
      }

      // Mark as processed
      await this.markEventProcessed(event.id);

      logger.info(`Market event processed successfully`, {
        eventId: event.id,
        notifiedUsers: relevantUsers.length,
      });
    } catch (error) {
      logger.error(`Failed to process market event ${event.id}`, {
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Find relevant users for an event
   */
  async findRelevantUsers(event) {
    try {
      const relevantUsers = [];

      // Get unique symbols and sectors from event
      const eventSymbols = event.symbols || [];
      const eventSectors = event.sectors || [];

      // Find users who have these symbols in portfolio or watchlist
      for (const symbol of eventSymbols) {
        const query = `
          SELECT DISTINCT
            u.id as user_id,
            p.symbol,
            'portfolio' as relevance_type
          FROM users u
          JOIN portfolios p ON u.id = p.user_id
          WHERE p.symbol = $1

          UNION

          SELECT DISTINCT
            u.id as user_id,
            w.symbol,
            'watchlist' as relevance_type
          FROM users u
          JOIN watchlists w ON u.id = w.user_id
          WHERE w.symbol = $1
        `;

        const result = await pool.query(query, [symbol]);

        for (const row of result.rows) {
          // Check if user already in list
          const existing = relevantUsers.find((u) => u.user_id === row.user_id);
          if (!existing) {
            relevantUsers.push({
              user_id: row.user_id,
              symbol: row.symbol,
              relevanceType: row.relevance_type,
            });
          }
        }
      }

      // Find users interested in these sectors
      for (const sector of eventSectors) {
        const query = `
          SELECT DISTINCT
            u.id as user_id,
            $1::text as symbol,
            'sector' as relevance_type
          FROM users u
          JOIN temporary_focus tf ON u.id = tf.user_id
          WHERE $1 = ANY(tf.targets)
            AND tf.status = 'monitoring'
        `;

        const result = await pool.query(query, [sector]);

        for (const row of result.rows) {
          const existing = relevantUsers.find((u) => u.user_id === row.user_id);
          if (!existing) {
            relevantUsers.push({
              user_id: row.user_id,
              symbol: sector,
              relevanceType: 'sector',
            });
          }
        }
      }

      return relevantUsers;
    } catch (error) {
      logger.error('Failed to find relevant users', {
        error: error.message,
        eventId: event.id,
      });
      return [];
    }
  }

  /**
   * Send event notification to user
   */
  async sendEventNotification(user, event) {
    try {
      // Calculate user-specific importance score
      const userContext = {
        inPortfolio: user.relevanceType === 'portfolio',
        inWatchlist: user.relevanceType === 'watchlist',
        inTemporaryFocus: user.relevanceType === 'sector',
      };

      // Get market data for symbol
      const marketData = await this.getMarketData(user.symbol);

      // Calculate importance score
      const scoreResult = await eventScoringEngine.calculateImportanceScore({
        symbol: user.symbol,
        marketData,
        news: [event],
        userContext,
      });

      // Only send if score is high enough
      if (scoreResult.totalScore < 40) {
        logger.debug('Event score too low, skipping notification', {
          userId: user.user_id,
          score: scoreResult.totalScore,
        });
        return;
      }

      // Generate notification message
      const title = `重要市场事件: ${user.symbol}`;
      const message = event.title;

      // Calculate priority based on score
      let priority = scoreResult.totalScore;

      // Boost priority for users with portfolio holdings
      if (userContext.inPortfolio) {
        priority = Math.min(100, priority + 10);
      }

      // Enqueue push notification
      const result = await pushNotificationQueue.enqueue({
        userId: user.user_id,
        title,
        message,
        priority,
        type: 'market_event',
        data: {
          eventId: event.id,
          symbol: user.symbol,
          importanceScore: scoreResult.totalScore,
          scoreLevel: scoreResult.level,
          category: event.category,
          url: event.url,
          relevanceType: user.relevanceType,
        },
      });

      if (result.success) {
        logger.info('Event notification queued', {
          userId: user.user_id,
          eventId: event.id,
          notificationId: result.notificationId,
          priority,
          score: scoreResult.totalScore,
        });
      }
    } catch (error) {
      logger.error('Failed to send event notification', {
        error: error.message,
        userId: user.user_id,
        eventId: event.id,
      });
      throw error;
    }
  }

  /**
   * Mark event as processed
   */
  async markEventProcessed(eventId) {
    try {
      await pool.query(
        'UPDATE news_events SET is_processed = true WHERE id = $1',
        [eventId]
      );
    } catch (error) {
      logger.error('Failed to mark event as processed', {
        error: error.message,
        eventId,
      });
      throw error;
    }
  }

  /**
   * Cleanup expired monitoring tasks
   */
  async cleanupExpiredTasks() {
    try {
      // Mark expired temporary focus items as completed
      const { markExpiredTemporaryFocus } = await import('./temporaryFocusService.js');
      const count = await markExpiredTemporaryFocus();

      if (count > 0) {
        logger.info(`Marked ${count} temporary focus items as expired`);
      }
    } catch (error) {
      logger.error('Failed to cleanup expired tasks', {
        error: error.message,
      });
    }
  }

  /**
   * Send push notification for triggered strategy
   */
  async sendStrategyPush(strategy, marketData, triggerReason) {
    try {
      // Generate notification message
      const { title, message } = await this.generateStrategyNotification(strategy, marketData, triggerReason);

      // Calculate priority based on strategy priority and market conditions
      let priority = strategy.priority || 50;

      // Boost priority for significant market moves
      if (marketData.price && marketData.price.change_percent) {
        const changeAbs = Math.abs(marketData.price.change_percent);
        if (changeAbs > 5) {
          priority = Math.min(100, priority + 30);
        } else if (changeAbs > 3) {
          priority = Math.min(100, priority + 15);
        }
      }

      // Enqueue push notification
      const result = await pushNotificationQueue.enqueue({
        userId: strategy.user_id,
        title,
        message,
        priority,
        type: 'strategy_trigger',
        data: {
          strategyId: strategy.id,
          symbol: strategy.symbol,
          conditionType: strategy.condition_type,
          triggerReason,
          marketData: {
            price: marketData.price?.close_price,
            change: marketData.price?.change_percent,
            timestamp: marketData.timestamp,
          },
        },
      });

      if (result.success) {
        logger.info('Strategy push notification queued', {
          strategyId: strategy.id,
          notificationId: result.notificationId,
          priority,
          queuePosition: result.queuePosition,
        });
      } else if (result.reason !== 'duplicate') {
        logger.warn('Failed to queue strategy push', {
          strategyId: strategy.id,
          reason: result.reason,
        });
      }
    } catch (error) {
      logger.error('Failed to send strategy push', {
        error: error.message,
        strategyId: strategy.id,
      });
      throw error;
    }
  }

  /**
   * Generate notification message for triggered strategy
   */
  async generateStrategyNotification(strategy, marketData, triggerReason) {
    const symbol = strategy.symbol;
    const price = marketData.price?.close_price;
    const change = marketData.price?.change_percent;

    let title = '';
    let message = '';

    switch (strategy.condition_type) {
      case 'price':
        if (strategy.conditions.priceAbove) {
          title = `价格突破: ${symbol}`;
          message = `${symbol} 突破 $${strategy.conditions.priceAbove}，当前价格 $${price?.toFixed(2)}`;
        } else if (strategy.conditions.priceBelow) {
          title = `价格跌破: ${symbol}`;
          message = `${symbol} 跌破 $${strategy.conditions.priceBelow}，当前价格 $${price?.toFixed(2)}`;
        } else if (strategy.conditions.percentChange) {
          const direction = change >= 0 ? '上涨' : '下跌';
          title = `价格异动: ${symbol}`;
          message = `${symbol} ${direction} ${Math.abs(change)?.toFixed(2)}%，当前价格 $${price?.toFixed(2)}`;
        }
        break;

      case 'technical':
        title = `技术信号: ${symbol}`;
        message = `${symbol} 技术指标触发信号`;
        if (marketData.technical?.rsi) {
          message += `，RSI: ${marketData.technical.rsi.toFixed(1)}`;
        }
        if (marketData.technical?.macd_histogram) {
          const macdSignal = marketData.technical.macd_histogram > 0 ? '看涨' : '看跌';
          message += `，MACD: ${macdSignal}`;
        }
        break;

      case 'news':
        title = `重要新闻: ${symbol}`;
        message = `${symbol} 有重要新闻发布，建议查看详情`;
        break;

      case 'time':
        title = `时间提醒: ${symbol}`;
        message = `您设置的 ${symbol} 时间条件已触发`;
        break;

      default:
        title = `策略触发: ${symbol}`;
        message = `${symbol} 策略条件已满足`;
    }

    // Append trigger reason if available
    if (triggerReason && !message.includes(triggerReason)) {
      message += `\n${triggerReason}`;
    }

    return { title, message };
  }

  /**
   * Get monitoring engine status
   */
  getStatus() {
    return {
      isRunning: this.isRunning,
      checkInterval: this.checkInterval,
      lastCheck: new Date(),
    };
  }
}

// Singleton instance
const monitoringEngine = new MonitoringEngine();

export default monitoringEngine;
