/**
 * LLM Analysis Routes for v2.0
 * Manages AI-generated analyses for strategies, focus items, and market events
 */

import express from 'express';
import llmAnalysisService from '../services/llmAnalysisService.js';
import { pool } from '../config/database.js';
import { responseHelpers } from '../middleware/responseFormatter.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { requireApiKey } from '../middleware/auth.js';
import logger from '../config/logger.js';

const router = express.Router();

// Apply response helpers middleware
router.use(responseHelpers);

/**
 * GET /api/analysis/strategy/:strategyId
 * Get strategy analysis
 */
router.get(
  '/strategy/:strategyId',
  asyncHandler(async (req, res) => {
    const { strategyId } = req.params;

    const query = `
      SELECT
        sa.*,
        s.symbol,
        s.name as strategy_name,
        s.condition_type
      FROM strategy_analyses sa
      JOIN strategies s ON sa.strategy_id = s.id
      WHERE sa.strategy_id = $1
      ORDER BY sa.created_at DESC
      LIMIT 1
    `;

    const result = await pool.query(query, [strategyId]);

    if (result.rows.length === 0) {
      return res.error('Analysis not found', 404);
    }

    return res.success({
      analysis: result.rows[0],
    });
  })
);

/**
 * POST /api/analysis/strategy/:strategyId/generate
 * Manually trigger strategy analysis generation
 * Requires admin API key
 */
router.post(
  '/strategy/:strategyId/generate',
  requireApiKey,
  asyncHandler(async (req, res) => {
    const { strategyId } = req.params;

    // Get strategy details
    const strategyResult = await pool.query(
      'SELECT * FROM strategies WHERE id = $1',
      [strategyId]
    );

    if (strategyResult.rows.length === 0) {
      return res.error('Strategy not found', 404);
    }

    const strategy = strategyResult.rows[0];

    // Get market data
    const [priceResult, techResult] = await Promise.all([
      pool.query('SELECT * FROM prices WHERE symbol = $1 ORDER BY timestamp DESC LIMIT 1', [strategy.symbol]),
      pool.query('SELECT * FROM technical_indicators WHERE symbol = $1 ORDER BY calculated_at DESC LIMIT 1', [strategy.symbol]),
    ]);

    const marketData = {
      price: priceResult.rows[0] || null,
      technical: techResult.rows[0] || null,
    };

    // Generate trigger reason
    const triggerReason = '手动触发的分析生成';

    // Generate analysis
    try {
      const analysis = await llmAnalysisService.generateStrategyAnalysis(
        strategy,
        marketData,
        triggerReason
      );

      return res.success({
        analysis,
        message: 'Analysis generated successfully',
      });
    } catch (error) {
      logger.error('Failed to generate strategy analysis', {
        error: error.message,
        strategyId,
      });
      return res.error('Failed to generate analysis', 500);
    }
  })
);

/**
 * GET /api/analysis/user/:userId/strategies
 * Get all strategy analyses for a user
 */
router.get(
  '/user/:userId/strategies',
  asyncHandler(async (req, res) => {
    const { userId } = req.params;
    const { limit = 20 } = req.query;

    const query = `
      SELECT
        sa.*,
        s.symbol,
        s.name as strategy_name,
        s.condition_type
      FROM strategy_analyses sa
      JOIN strategies s ON sa.strategy_id = s.id
      WHERE sa.user_id = $1
      ORDER BY sa.created_at DESC
      LIMIT $2
    `;

    const result = await pool.query(query, [userId, parseInt(limit)]);

    return res.success({
      analyses: result.rows,
      count: result.rows.length,
    });
  })
);

/**
 * GET /api/analysis/focus/:focusItemId
 * Get focus item analysis
 */
router.get(
  '/focus/:focusItemId',
  asyncHandler(async (req, res) => {
    const { focusItemId } = req.params;

    const query = `
      SELECT
        fa.*,
        tf.title as focus_title,
        tf.status
      FROM focus_analyses fa
      JOIN temporary_focus tf ON fa.focus_item_id = tf.id
      WHERE fa.focus_item_id = $1
      ORDER BY fa.created_at DESC
      LIMIT 1
    `;

    const result = await pool.query(query, [focusItemId]);

    if (result.rows.length === 0) {
      return res.error('Analysis not found', 404);
    }

    return res.success({
      analysis: result.rows[0],
    });
  })
);

/**
 * POST /api/analysis/focus/:focusItemId/generate
 * Manually trigger focus item analysis generation
 * Requires admin API key
 */
router.post(
  '/focus/:focusItemId/generate',
  requireApiKey,
  asyncHandler(async (req, res) => {
    const { focusItemId } = req.params;

    // Get focus item details
    const focusResult = await pool.query(
      'SELECT * FROM temporary_focus WHERE id = $1',
      [focusItemId]
    );

    if (focusResult.rows.length === 0) {
      return res.error('Focus item not found', 404);
    }

    const focusItem = focusResult.rows[0];

    // Get findings (mock for now)
    const findings = [];

    // Generate analysis
    try {
      const analysis = await llmAnalysisService.generateFocusAnalysis(
        focusItem,
        findings
      );

      return res.success({
        analysis,
        message: 'Analysis generated successfully',
      });
    } catch (error) {
      logger.error('Failed to generate focus analysis', {
        error: error.message,
        focusItemId,
      });
      return res.error('Failed to generate analysis', 500);
    }
  })
);

/**
 * GET /api/analysis/user/:userId/focus
 * Get all focus analyses for a user
 */
router.get(
  '/user/:userId/focus',
  asyncHandler(async (req, res) => {
    const { userId } = req.params;
    const { limit = 20 } = req.query;

    const query = `
      SELECT
        fa.*,
        tf.title as focus_title,
        tf.status
      FROM focus_analyses fa
      JOIN temporary_focus tf ON fa.focus_item_id = tf.id
      WHERE fa.user_id = $1
      ORDER BY fa.created_at DESC
      LIMIT $2
    `;

    const result = await pool.query(query, [userId, parseInt(limit)]);

    return res.success({
      analyses: result.rows,
      count: result.rows.length,
    });
  })
);

/**
 * GET /api/analysis/event/:eventId
 * Get market event analysis
 */
router.get(
  '/event/:eventId',
  asyncHandler(async (req, res) => {
    const { eventId } = req.params;

    const query = `
      SELECT
        ea.*,
        ne.title as event_title,
        ne.category,
        ne.importance_score
      FROM event_analyses ea
      JOIN news_events ne ON ea.event_id = ne.id
      WHERE ea.event_id = $1
      ORDER BY ea.created_at DESC
      LIMIT 1
    `;

    const result = await pool.query(query, [eventId]);

    if (result.rows.length === 0) {
      return res.error('Analysis not found', 404);
    }

    return res.success({
      analysis: result.rows[0],
    });
  })
);

/**
 * POST /api/analysis/event/:eventId/generate
 * Manually trigger event analysis generation
 * Requires admin API key
 */
router.post(
  '/event/:eventId/generate',
  requireApiKey,
  asyncHandler(async (req, res) => {
    const { eventId } = req.params;

    // Get event details
    const eventResult = await pool.query(
      'SELECT * FROM news_events WHERE id = $1',
      [eventId]
    );

    if (eventResult.rows.length === 0) {
      return res.error('Event not found', 404);
    }

    const event = eventResult.rows[0];

    // Get affected symbols
    const affectedSymbols = event.symbols || [];

    // Generate analysis
    try {
      const analysis = await llmAnalysisService.generateEventAnalysis(
        event,
        affectedSymbols
      );

      return res.success({
        analysis,
        message: 'Analysis generated successfully',
      });
    } catch (error) {
      logger.error('Failed to generate event analysis', {
        error: error.message,
        eventId,
      });
      return res.error('Failed to generate analysis', 500);
    }
  })
);

/**
 * GET /api/analysis/events
 * Get all event analyses
 */
router.get(
  '/events',
  asyncHandler(async (req, res) => {
    const { limit = 20 } = req.query;

    const query = `
      SELECT
        ea.*,
        ne.title as event_title,
        ne.category,
        ne.importance_score
      FROM event_analyses ea
      JOIN news_events ne ON ea.event_id = ne.id
      ORDER BY ea.created_at DESC
      LIMIT $1
    `;

    const result = await pool.query(query, [parseInt(limit)]);

    return res.success({
      analyses: result.rows,
      count: result.rows.length,
    });
  })
);

/**
 * GET /api/analysis/stats
 * Get analysis statistics
 */
router.get(
  '/stats',
  asyncHandler(async (req, res) => {
    // Get strategy analysis stats
    const strategyStatsQuery = `
      SELECT
        COUNT(*) as total_analyses,
        AVG(confidence) as avg_confidence,
        COUNT(DISTINCT user_id) as total_users,
        COUNT(DISTINCT strategy_id) as total_strategies
      FROM strategy_analyses
    `;

    // Get focus analysis stats
    const focusStatsQuery = `
      SELECT
        COUNT(*) as total_analyses,
        AVG(confidence) as avg_confidence,
        COUNT(DISTINCT user_id) as total_users,
        COUNT(DISTINCT focus_item_id) as total_items
      FROM focus_analyses
    `;

    // Get event analysis stats
    const eventStatsQuery = `
      SELECT
        COUNT(*) as total_analyses,
        AVG(confidence) as avg_confidence,
        COUNT(DISTINCT event_id) as total_events
      FROM event_analyses
    `;

    // Get recent analysis count (last 24 hours)
    const recentQuery = `
      SELECT
        COUNT(*) as recent_analyses
      FROM (
        SELECT created_at FROM strategy_analyses
        UNION ALL
        SELECT created_at FROM focus_analyses
        UNION ALL
        SELECT created_at FROM event_analyses
      ) all_analyses
      WHERE created_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
    `;

    const [strategyStats, focusStats, eventStats, recentStats] = await Promise.all([
      pool.query(strategyStatsQuery),
      pool.query(focusStatsQuery),
      pool.query(eventStatsQuery),
      pool.query(recentQuery),
    ]);

    return res.success({
      strategyAnalyses: strategyStats.rows[0],
      focusAnalyses: focusStats.rows[0],
      eventAnalyses: eventStats.rows[0],
      recent: recentStats.rows[0],
      timestamp: new Date(),
    });
  })
);

/**
 * DELETE /api/analysis/strategy/:strategyId
 * Delete strategy analysis
 * Requires admin API key
 */
router.delete(
  '/strategy/:strategyId',
  requireApiKey,
  asyncHandler(async (req, res) => {
    const { strategyId } = req.params;

    const result = await pool.query(
      'DELETE FROM strategy_analyses WHERE strategy_id = $1',
      [strategyId]
    );

    return res.success({
      deleted: result.rowCount,
      message: 'Strategy analysis deleted successfully',
    });
  })
);

/**
 * DELETE /api/analysis/focus/:focusItemId
 * Delete focus analysis
 * Requires admin API key
 */
router.delete(
  '/focus/:focusItemId',
  requireApiKey,
  asyncHandler(async (req, res) => {
    const { focusItemId } = req.params;

    const result = await pool.query(
      'DELETE FROM focus_analyses WHERE focus_item_id = $1',
      [focusItemId]
    );

    return res.success({
      deleted: result.rowCount,
      message: 'Focus analysis deleted successfully',
    });
  })
);

/**
 * DELETE /api/analysis/event/:eventId
 * Delete event analysis
 * Requires admin API key
 */
router.delete(
  '/event/:eventId',
  requireApiKey,
  asyncHandler(async (req, res) => {
    const { eventId } = req.params;

    const result = await pool.query(
      'DELETE FROM event_analyses WHERE event_id = $1',
      [eventId]
    );

    return res.success({
      deleted: result.rowCount,
      message: 'Event analysis deleted successfully',
    });
  })
);

export default router;
