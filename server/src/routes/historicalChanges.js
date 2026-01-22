/**
 * Historical Price Changes Routes
 * Provides endpoint for fetching historical price changes for a symbol
 */

import express from 'express';
import { asyncHandler } from '../middleware/errorHandler.js';
import priceChangeCalculator from '../services/priceChangeCalculator.js';
import logger from '../config/logger.js';

const router = express.Router();

/**
 * GET /api/historical-changes/:symbol/history
 * Get historical price changes for a specific symbol
 * @param {string} symbol - Stock/index symbol (e.g., "000001.SS", "SPY")
 */
router.get(
  '/:symbol/history',
  asyncHandler(async (req, res) => {
    const { symbol } = req.params;

    // Validate symbol parameter
    if (!symbol || typeof symbol !== 'string') {
      logger.warn('Invalid symbol parameter', { symbol });
      return res.status(400).json({
        success: false,
        error: 'Symbol parameter is required and must be a string',
      });
    }

    logger.info('Fetching historical price changes', { symbol });

    try {
      // Calculate price changes for all time periods
      const changes = await priceChangeCalculator.calculatePriceChange(symbol);

      logger.info('Historical price changes fetched successfully', {
        symbol,
        periods: Object.keys(changes).length,
      });

      return res.json({
        success: true,
        data: {
          symbol,
          changes,
        },
      });
    } catch (error) {
      logger.error('Failed to fetch historical price changes', {
        symbol,
        error: error.message,
      });

      return res.status(500).json({
        success: false,
        error: error.message || 'Failed to calculate historical price changes',
      });
    }
  })
);

export default router;
