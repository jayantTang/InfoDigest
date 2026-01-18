/**
 * Monitoring Engine Routes for v2.0
 * Manages monitoring engine status and configuration
 */

import express from 'express';
import monitoringEngine from '../services/monitoringEngine.js';
import pushNotificationQueue from '../services/pushNotificationQueue.js';
import { pool } from '../config/database.js';
import { responseHelpers } from '../middleware/responseFormatter.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { requireApiKey } from '../middleware/auth.js';
import logger from '../config/logger.js';

const router = express.Router();

// Apply response helpers middleware
router.use(responseHelpers);

/**
 * GET /api/monitoring/status
 * Get monitoring engine status
 */
router.get(
  '/status',
  asyncHandler(async (req, res) => {
    const status = monitoringEngine.getStatus();
    const queueStatus = pushNotificationQueue.getStatus();

    return res.success({
      monitoring: status,
      pushQueue: queueStatus,
      timestamp: new Date(),
    });
  })
);

/**
 * POST /api/monitoring/start
 * Start the monitoring engine
 * Requires admin API key
 */
router.post(
  '/start',
  requireApiKey,
  asyncHandler(async (req, res) => {
    logger.info('Manual monitoring engine start requested');

    await monitoringEngine.start();

    // Also start push notification queue
    pushNotificationQueue.start();

    return res.success({
      message: 'Monitoring engine started',
      status: monitoringEngine.getStatus(),
    });
  })
);

/**
 * POST /api/monitoring/stop
 * Stop the monitoring engine
 * Requires admin API key
 */
router.post(
  '/stop',
  requireApiKey,
  asyncHandler(async (req, res) => {
    logger.info('Manual monitoring engine stop requested');

    monitoringEngine.stop();

    // Also stop push notification queue
    pushNotificationQueue.stop();

    return res.success({
      message: 'Monitoring engine stopped',
      status: monitoringEngine.getStatus(),
    });
  })
);

/**
 * POST /api/monitoring/check-cycle
 * Trigger a single monitoring cycle manually
 * Requires admin API key
 */
router.post(
  '/check-cycle',
  requireApiKey,
  asyncHandler(async (req, res) => {
    logger.info('Manual monitoring cycle requested');

    await monitoringEngine.runMonitoringCycle();

    return res.success({
      message: 'Monitoring cycle completed',
      timestamp: new Date(),
    });
  })
);

/**
 * GET /api/monitoring/strategies
 * Get all active strategies
 */
router.get(
  '/strategies',
  asyncHandler(async (req, res) => {
    const { user_id } = req.query;

    let query = `
      SELECT
        s.id,
        s.user_id,
        s.symbol,
        s.name,
        s.condition_type,
        s.conditions,
        s.action,
        s.priority,
        s.status,
        s.created_at,
        s.last_triggered_at,
        s.trigger_count
      FROM strategies s
      WHERE s.status = 'active'
    `;

    const params = [];

    if (user_id) {
      query += ' AND s.user_id = $1';
      params.push(user_id);
    }

    query += ' ORDER BY s.priority DESC, s.created_at DESC';

    const result = await pool.query(query, params);

    return res.success({
      strategies: result.rows,
      count: result.rows.length,
    });
  })
);

/**
 * GET /api/monitoring/strategies/:id
 * Get strategy details
 */
router.get(
  '/strategies/:id',
  asyncHandler(async (req, res) => {
    const { id } = req.params;

    const query = `
      SELECT
        s.*,
        u.push_enabled,
        u.push_token IS NOT NULL as has_push_token
      FROM strategies s
      JOIN users u ON s.user_id = u.id
      WHERE s.id = $1
    `;

    const result = await pool.query(query, [id]);

    if (result.rows.length === 0) {
      return res.error('Strategy not found', 404);
    }

    // Get trigger history
    const historyQuery = `
      SELECT
        triggered_at,
        trigger_reason,
        market_data
      FROM strategy_triggers
      WHERE strategy_id = $1
      ORDER BY triggered_at DESC
      LIMIT 10
    `;

    const historyResult = await pool.query(historyQuery, [id]);

    return res.success({
      strategy: result.rows[0],
      triggerHistory: historyResult.rows,
    });
  })
);

/**
 * POST /api/monitoring/strategies/:id/test
 * Test if a strategy would trigger now
 */
router.post(
  '/strategies/:id/test',
  asyncHandler(async (req, res) => {
    const { id } = req.params;

    // Get strategy
    const strategyResult = await pool.query('SELECT * FROM strategies WHERE id = $1', [id]);

    if (strategyResult.rows.length === 0) {
      return res.error('Strategy not found', 404);
    }

    const strategy = strategyResult.rows[0];

    // Evaluate strategy
    const wouldTrigger = await monitoringEngine.evaluateStrategy(strategy);

    // Get current market data
    const marketData = await monitoringEngine.getMarketData(strategy.symbol);

    return res.success({
      strategyId: id,
      symbol: strategy.symbol,
      wouldTrigger,
      marketData,
      timestamp: new Date(),
    });
  })
);

/**
 * GET /api/monitoring/focus-items
 * Get temporary focus items
 */
router.get(
  '/focus-items',
  asyncHandler(async (req, res) => {
    const { user_id, status } = req.query;

    let query = `
      SELECT
        tf.id,
        tf.user_id,
        tf.title,
        tf.targets,
        tf.focus,
        tf.status,
        tf.created_at,
        tf.updated_at,
        tf.expires_at
      FROM temporary_focus tf
      WHERE 1=1
    `;

    const params = [];
    let paramIndex = 1;

    if (user_id) {
      query += ` AND tf.user_id = $${paramIndex++}`;
      params.push(user_id);
    }

    if (status) {
      query += ` AND tf.status = $${paramIndex++}`;
      params.push(status);
    }

    query += ' ORDER BY tf.created_at DESC';

    const result = await pool.query(query, params);

    return res.success({
      focusItems: result.rows,
      count: result.rows.length,
    });
  })
);

/**
 * GET /api/monitoring/events
 * Get recent market events
 */
router.get(
  '/events',
  asyncHandler(async (req, res) => {
    const { processed, limit = 20 } = req.query;

    let query = `
      SELECT
        id,
        title,
        description,
        symbols,
        sectors,
        category,
        importance_score,
        published_at,
        fetched_at,
        is_processed
      FROM news_events
      WHERE 1=1
    `;

    const params = [];
    let paramIndex = 1;

    if (processed !== undefined) {
      query += ` AND is_processed = $${paramIndex++}`;
      params.push(processed === 'true');
    }

    query += ' ORDER BY importance_score DESC, published_at DESC LIMIT $' + paramIndex++;
    params.push(parseInt(limit));

    const result = await pool.query(query, params);

    return res.success({
      events: result.rows,
      count: result.rows.length,
    });
  })
);

/**
 * GET /api/monitoring/queue
 * Get push notification queue status
 */
router.get(
  '/queue',
  asyncHandler(async (req, res) => {
    const { user_id } = req.query;

    const status = pushNotificationQueue.getStatus();
    const pending = pushNotificationQueue.getPendingNotifications(user_id);

    return res.success({
      ...status,
      pending,
    });
  })
);

/**
 * POST /api/monitoring/queue/clear
 * Clear push notification queue
 * Requires admin API key
 */
router.post(
  '/queue/clear',
  requireApiKey,
  asyncHandler(async (req, res) => {
    logger.info('Push notification queue clear requested');

    const result = pushNotificationQueue.clearQueue();

    return res.success({
      message: 'Queue cleared',
      ...result,
    });
  })
);

/**
 * GET /api/monitoring/metrics
 * Get monitoring metrics
 */
router.get(
  '/metrics',
  asyncHandler(async (req, res) => {
    // Get strategy trigger stats
    const strategyStatsQuery = `
      SELECT
        COUNT(*) as total_strategies,
        COUNT(*) FILTER (WHERE status = 'active') as active_strategies,
        SUM(trigger_count) as total_triggers,
        AVG(trigger_count) as avg_triggers
      FROM strategies
    `;

    // Get trigger history stats (last 7 days)
    const triggerHistoryQuery = `
      SELECT
        DATE(triggered_at) as date,
        COUNT(*) as trigger_count
      FROM strategy_triggers
      WHERE triggered_at >= CURRENT_DATE - INTERVAL '7 days'
      GROUP BY DATE(triggered_at)
      ORDER BY date DESC
    `;

    // Get focus item stats
    const focusStatsQuery = `
      SELECT
        COUNT(*) as total_focus_items,
        COUNT(*) FILTER (WHERE status = 'monitoring') as active_focus_items,
        COUNT(*) FILTER (WHERE status = 'completed') as completed_focus_items,
        COUNT(*) FILTER (WHERE status = 'expired') as expired_focus_items
      FROM temporary_focus
    `;

    // Get event stats
    const eventStatsQuery = `
      SELECT
        COUNT(*) as total_events,
        COUNT(*) FILTER (WHERE importance_score >= 80) as critical_events,
        COUNT(*) FILTER (WHERE is_processed = true) as processed_events,
        AVG(importance_score) as avg_importance
      FROM news_events
      WHERE published_at >= CURRENT_DATE
    `;

    const [strategyStats, triggerHistory, focusStats, eventStats] = await Promise.all([
      pool.query(strategyStatsQuery),
      pool.query(triggerHistoryQuery),
      pool.query(focusStatsQuery),
      pool.query(eventStatsQuery),
    ]);

    return res.success({
      strategies: strategyStats.rows[0],
      triggerHistory: triggerHistory.rows,
      focusItems: focusStats.rows[0],
      events: eventStats.rows[0],
      timestamp: new Date(),
    });
  })
);

export default router;
