/**
 * Market Events API Routes
 * Provides endpoints for market events management
 */

import express from 'express';
import { responseHelpers } from '../middleware/responseFormatter.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { requireApiKey } from '../middleware/auth.js';
import { MarketEventsScheduler } from '../services/marketEventsScheduler.js';
import { pool } from '../config/database.js';
import logger from '../config/logger.js';

const router = express.Router();

// Apply response helpers middleware
router.use(responseHelpers);

/**
 * GET /api/market-events/history
 * Get historical market events digest messages
 */
router.get(
  '/history',
  asyncHandler(async (req, res) => {
    const { limit = 10, offset = 0 } = req.query;

    const query = `
      SELECT
        id, message_type, title, summary,
        created_at, sent_at
      FROM messages
      WHERE message_type = 'market_events'
      ORDER BY created_at DESC
      LIMIT $1 OFFSET $2
    `;

    const result = await pool.query(query, [parseInt(limit), parseInt(offset)]);

    // Get total count
    const countQuery = `
      SELECT COUNT(*) as total
      FROM messages
      WHERE message_type = 'market_events'
    `;
    const countResult = await pool.query(countQuery);

    return res.success({
      messages: result.rows,
      pagination: {
        total: parseInt(countResult.rows[0].total),
        limit: parseInt(limit),
        offset: parseInt(offset),
      },
    });
  })
);

/**
 * GET /api/market-events/stats
 * Get market events statistics
 */
router.get(
  '/stats',
  asyncHandler(async (req, res) => {
    // Get events stats from last 24 hours
    const eventsStatsQuery = `
      SELECT
        COUNT(*) as total_events,
        COUNT(*) FILTER (WHERE importance_score >= 80) as critical_events,
        COUNT(*) FILTER (WHERE importance_score >= 60 AND importance_score < 80) as high_events,
        COUNT(*) FILTER (WHERE is_processed = true) as processed_events,
        COUNT(*) FILTER (WHERE is_processed = false) as pending_events,
        AVG(importance_score) as avg_importance
      FROM news_events
      WHERE published_at >= CURRENT_DATE
    `;

    // Get messages stats
    const messagesStatsQuery = `
      SELECT
        COUNT(*) as total_digests,
        COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE) as today_digests,
        MAX(created_at) as last_digest_at
      FROM messages
      WHERE message_type = 'market_events'
    `;

    // Get category distribution
    const categoryQuery = `
      SELECT
        category,
        COUNT(*) as count
      FROM news_events
      WHERE published_at >= CURRENT_DATE
      GROUP BY category
      ORDER BY count DESC
    `;

    const [eventsStats, messagesStats, categoryStats] = await Promise.all([
      pool.query(eventsStatsQuery),
      pool.query(messagesStatsQuery),
      pool.query(categoryQuery),
    ]);

    return res.success({
      events: eventsStats.rows[0],
      messages: messagesStats.rows[0],
      categoryDistribution: categoryStats.rows,
      timestamp: new Date(),
    });
  })
);

/**
 * POST /api/market-events/generate
 * Manually trigger a market events digest generation
 * Requires admin API key
 */
router.post(
  '/generate',
  requireApiKey,
  asyncHandler(async (req, res) => {
    logger.info('Manual market events generation requested');

    const marketEventsScheduler = new MarketEventsScheduler();
    const result = await marketEventsScheduler.runOnce();

    if (result.success) {
      return res.success({
        message: 'Market events digest generated successfully',
        data: result,
      });
    } else {
      return res.error(result.error || 'Generation failed', 500);
    }
  })
);

/**
 * GET /api/market-events/latest
 * Get the latest market events digest
 */
router.get(
  '/latest',
  asyncHandler(async (req, res) => {
    const query = `
      SELECT
        id, title, summary, content_rich,
        source_data, created_at, sent_at
      FROM messages
      WHERE message_type = 'market_events'
      ORDER BY created_at DESC
      LIMIT 1
    `;

    const result = await pool.query(query);

    if (result.rows.length === 0) {
      return res.error('No market events digest found', 404);
    }

    return res.success({
      digest: result.rows[0],
    });
  })
);

/**
 * GET /api/market-events/pending
 * Get pending (unprocessed) market events
 */
router.get(
  '/pending',
  asyncHandler(async (req, res) => {
    const { limit = 20 } = req.query;

    const query = `
      SELECT
        id, title, description, category,
        importance_score, symbols, published_at
      FROM news_events
      WHERE is_processed = false
      ORDER BY importance_score DESC, published_at DESC
      LIMIT $1
    `;

    const result = await pool.query(query, [parseInt(limit)]);

    return res.success({
      events: result.rows,
      count: result.rows.length,
    });
  })
);

export default router;
