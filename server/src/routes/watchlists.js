/**
 * Watchlist Routes for v2.0
 * Handles watchlist CRUD operations
 */

import express from 'express';
import {
  getUserWatchlists,
  getWatchlistById,
  createWatchlist,
  updateWatchlist,
  deleteWatchlist,
  getWatchlistSummary,
} from '../services/watchlistService.js';
import { requireDeviceToken, requireUser } from '../middleware/auth.js';
import { responseHelpers } from '../middleware/responseFormatter.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { validateWatchlist, ValidationError } from '../utils/validators.js';
import logger from '../config/logger.js';

const router = express.Router();

// Apply response helpers middleware
router.use(responseHelpers);

/**
 * GET /api/watchlists
 * Get all watchlist items for current user
 * Query params: ?assetType=stock&reason=potential_buy
 */
router.get(
  '/',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const filters = {};

    if (req.query.assetType) {
      filters.assetType = req.query.assetType;
    }

    if (req.query.reason) {
      filters.reason = req.query.reason;
    }

    const watchlists = await getUserWatchlists(req.userId, filters);

    return res.success({
      watchlists: watchlists.map((w) => ({
        id: w.id,
        symbol: w.symbol,
        assetType: w.asset_type,
        exchange: w.exchange,
        reason: w.reason,
        notes: w.notes,
        focus: w.focus,
        priority: w.priority,
        createdAt: w.created_at,
        updatedAt: w.updated_at,
      })),
    });
  })
);

/**
 * GET /api/watchlists/summary
 * Get watchlist summary
 */
router.get(
  '/summary',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const summary = await getWatchlistSummary(req.userId);

    return res.success(summary);
  })
);

/**
 * GET /api/watchlists/:id
 * Get specific watchlist item by ID
 */
router.get(
  '/:id',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const watchlist = await getWatchlistById(req.params.id, req.userId);

    if (!watchlist) {
      return res.error('Watchlist item not found', 404);
    }

    return res.success({
      watchlist: {
        id: watchlist.id,
        symbol: watchlist.symbol,
        assetType: watchlist.asset_type,
        exchange: watchlist.exchange,
        reason: watchlist.reason,
        notes: watchlist.notes,
        focus: watchlist.focus,
        priority: watchlist.priority,
        createdAt: watchlist.created_at,
        updatedAt: watchlist.updated_at,
      },
    });
  })
);

/**
 * POST /api/watchlists
 * Create new watchlist item
 *
 * Request body:
 * {
 *   "symbol": "AMD",
 *   "assetType": "stock",
 *   "exchange": "NASDAQ",
 *   "reason": "potential_buy",
 *   "notes": "Monitoring for entry point",
 *   "focus": {
 *     "price": true,
 *     "news": true,
 *     "technical": false,
 *     "sector": false
 *   },
 *   "priority": 7
 * }
 */
router.post(
  '/',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const validation = validateWatchlist(req.body);

    if (!validation.valid) {
      throw new ValidationError(validation.errors);
    }

    const watchlist = await createWatchlist(req.userId, req.body);

    logger.info('Watchlist created via API', {
      watchlistId: watchlist.id,
      userId: req.userId,
      symbol: watchlist.symbol,
    });

    return res.success(
      {
        watchlist: {
          id: watchlist.id,
          symbol: watchlist.symbol,
          assetType: watchlist.asset_type,
          exchange: watchlist.exchange,
          reason: watchlist.reason,
          notes: watchlist.notes,
          focus: watchlist.focus,
          priority: watchlist.priority,
          createdAt: watchlist.created_at,
        },
      },
      201
    );
  })
);

/**
 * PUT /api/watchlists/:id
 * Update watchlist item
 *
 * Request body:
 * {
 *   "reason": "potential_buy",
 *   "notes": "Updated notes",
 *   "focus": {...},
 *   "priority": 8
 * }
 */
router.put(
  '/:id',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const watchlist = await updateWatchlist(req.params.id, req.userId, req.body);

    logger.info('Watchlist updated via API', {
      watchlistId: watchlist.id,
      userId: req.userId,
      updates: Object.keys(req.body),
    });

    return res.success({
      watchlist: {
        id: watchlist.id,
        symbol: watchlist.symbol,
        assetType: watchlist.asset_type,
        exchange: watchlist.exchange,
        reason: watchlist.reason,
        notes: watchlist.notes,
        focus: watchlist.focus,
        priority: watchlist.priority,
        updatedAt: watchlist.updated_at,
      },
    });
  })
);

/**
 * DELETE /api/watchlists/:id
 * Delete watchlist item
 */
router.delete(
  '/:id',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    await deleteWatchlist(req.params.id, req.userId);

    logger.info('Watchlist deleted via API', {
      watchlistId: req.params.id,
      userId: req.userId,
    });

    return res.success({
      message: 'Watchlist item deleted successfully',
    });
  })
);

export default router;
