/**
 * Data Collection Routes for v2.0
 * Manages data collection status and health monitoring
 */

import express from 'express';
import dataCollector from '../services/dataCollector.js';
import { responseHelpers } from '../middleware/responseFormatter.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { requireApiKey } from '../middleware/auth.js';
import logger from '../config/logger.js';

const router = express.Router();

// Apply response helpers middleware
router.use(responseHelpers);

/**
 * GET /api/data-collection/status
 * Get data collection status
 */
router.get(
  '/status',
  asyncHandler(async (req, res) => {
    const status = await dataCollector.getStatus();

    return res.success(status);
  })
);

/**
 * POST /api/data-collection/collect-all
 * Trigger data collection for all sources
 * Requires admin API key
 */
router.post(
  '/collect-all',
  requireApiKey,
  asyncHandler(async (req, res) => {
    logger.info('Manual data collection triggered');

    const result = await dataCollector.collectAll();

    return res.success(result);
  })
);

/**
 * POST /api/data-collection/collect/:source
 * Trigger data collection for specific source
 * Requires admin API key
 */
router.post(
  '/collect/:source',
  requireApiKey,
  asyncHandler(async (req, res) => {
    const source = req.params.source;

    logger.info(`Manual data collection triggered for ${source}`);

    const result = await dataCollector.collectOne(source);

    return res.success(result);
  })
);

/**
 * GET /api/data-collection/sources
 * Get status of all data sources
 */
router.get(
  '/sources',
  asyncHandler(async (req, res) => {
    const { default: db } = await import('../config/database.js');

    const query = `
      SELECT
        source_name,
        source_type,
        is_active,
        last_fetch_at,
        last_error,
        error_count,
        updated_at
      FROM data_source_status
      ORDER BY source_name
    `;

    const result = await db.pool.query(query);

    return res.success({
      sources: result.rows,
    });
  })
);

/**
 * GET /api/data-collection/health
 * Get health status of data collection system
 */
router.get(
  '/health',
  asyncHandler(async (req, res) => {
    const { default: db } = await import('../config/database.js');

    // Get data source stats
    const query = `
      SELECT
        COUNT(*) as total_sources,
        COUNT(*) FILTER (WHERE is_active = true) as active_sources,
        SUM(error_count) as total_errors
      FROM data_source_status
    `;

    const result = await db.pool.query(query);
    const stats = result.rows[0];

    // Get recent data counts
    const [priceCount, newsCount, cryptoCount] = await Promise.all([
      db.pool.query("SELECT COUNT(*) as count FROM prices WHERE timestamp >= CURRENT_DATE"),
      db.pool.query("SELECT COUNT(*) as count FROM news_events WHERE fetched_at >= CURRENT_DATE"),
      db.pool.query("SELECT COUNT(*) as count FROM crypto_assets WHERE updated_at >= CURRENT_DATE"),
    ]);

    const health = {
      status: stats.active_sources > 0 ? 'healthy' : 'degraded',
      timestamp: new Date().toISOString(),
      sources: {
        total: parseInt(stats.total_sources),
        active: parseInt(stats.active_sources),
        errors: parseInt(stats.total_errors || 0),
      },
      today: {
        prices: parseInt(priceCount.rows[0].count),
        news: parseInt(newsCount.rows[0].count),
        cryptoAssets: parseInt(cryptoCount.rows[0].count),
      },
    };

    return res.success(health);
  })
);

/**
 * GET /api/data-collection/metrics
 * Get detailed collection metrics
 */
router.get(
  '/metrics',
  asyncHandler(async (req, res) => {
    const { default: db } = await import('../config/database.js');

    // Get collection history (last 7 days)
    const query = `
      SELECT
        DATE_TRUNC('day', timestamp) as date,
        COUNT(*) as record_count
      FROM prices
      WHERE timestamp >= CURRENT_DATE - INTERVAL '7 days'
      GROUP BY DATE_TRUNC('day', timestamp)
      ORDER BY date DESC
    `;

    const result = await db.pool.query(query);

    return res.success({
      metrics: result.rows,
    });
  })
);

export default router;
