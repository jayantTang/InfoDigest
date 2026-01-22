/**
 * Historical Price Changes Routes
 * Provides endpoint for fetching historical price changes for a symbol
 */

import express from 'express';
import { responseHelpers } from '../middleware/responseFormatter.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import priceChangeCalculator from '../services/priceChangeCalculator.js';
import logger from '../config/logger.js';

const router = express.Router();

router.use(responseHelpers);

/**
 * GET /api/historical-changes/:symbol
 * Get historical price changes for a specific symbol
 * @param {string} symbol - Stock/index symbol (e.g., "000001.SS", "SPY")
 */
router.get(
  '/:symbol',
  asyncHandler(async (req, res) => {
    const { symbol } = req.params;

    logger.info('Fetching historical changes', { symbol });

    const changes = await priceChangeCalculator.calculatePriceChange(symbol);

    logger.info('Historical changes retrieved', {
      symbol,
      availablePeriods: Object.values(changes).filter(c => c.available).length,
    });

    return res.success({
      symbol,
      changes,
    });
  })
);

export default router;
