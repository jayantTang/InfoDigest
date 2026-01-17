/**
 * Portfolio Routes for v2.0
 * Handles portfolio position CRUD operations
 */

import express from 'express';
import {
  getUserPortfolios,
  getPortfolioById,
  createPortfolio,
  updatePortfolio,
  deletePortfolio,
  getPortfolioSummary,
} from '../services/portfolioService.js';
import { requireDeviceToken, requireUser } from '../middleware/auth.js';
import { responseHelpers } from '../middleware/responseFormatter.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { validatePortfolio, ValidationError } from '../utils/validators.js';
import logger from '../config/logger.js';

const router = express.Router();

// Apply response helpers middleware
router.use(responseHelpers);

/**
 * GET /api/portfolios
 * Get all portfolios for current user
 * Query params: ?status=active&assetType=stock
 */
router.get(
  '/',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const filters = {};

    if (req.query.status) {
      filters.status = req.query.status;
    }

    if (req.query.assetType) {
      filters.assetType = req.query.assetType;
    }

    const portfolios = await getUserPortfolios(req.userId, filters);

    return res.success({
      portfolios: portfolios.map((p) => ({
        id: p.id,
        symbol: p.symbol,
        assetType: p.asset_type,
        exchange: p.exchange,
        shares: parseFloat(p.shares),
        avgCost: parseFloat(p.avg_cost),
        currentPrice: p.current_price ? parseFloat(p.current_price) : null,
        unrealizedPnL: p.unrealized_pnl ? parseFloat(p.unrealized_pnl) : null,
        totalValue: p.total_value ? parseFloat(p.total_value) : null,
        openedAt: p.opened_at,
        lastUpdated: p.last_updated,
        alerts: p.alerts,
        status: p.status,
        createdAt: p.created_at,
        updatedAt: p.updated_at,
      })),
    });
  })
);

/**
 * GET /api/portfolios/summary
 * Get portfolio summary
 */
router.get(
  '/summary',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const summary = await getPortfolioSummary(req.userId);

    return res.success(summary);
  })
);

/**
 * GET /api/portfolios/:id
 * Get specific portfolio by ID
 */
router.get(
  '/:id',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const portfolio = await getPortfolioById(req.params.id, req.userId);

    if (!portfolio) {
      return res.error('Portfolio not found', 404);
    }

    return res.success({
      portfolio: {
        id: portfolio.id,
        symbol: portfolio.symbol,
        assetType: portfolio.asset_type,
        exchange: portfolio.exchange,
        shares: parseFloat(portfolio.shares),
        avgCost: parseFloat(portfolio.avg_cost),
        currentPrice: portfolio.current_price ? parseFloat(portfolio.current_price) : null,
        unrealizedPnL: portfolio.unrealized_pnl ? parseFloat(portfolio.unrealized_pnl) : null,
        totalValue: portfolio.total_value ? parseFloat(portfolio.total_value) : null,
        openedAt: portfolio.opened_at,
        lastUpdated: portfolio.last_updated,
        alerts: portfolio.alerts,
        status: portfolio.status,
        createdAt: portfolio.created_at,
        updatedAt: portfolio.updated_at,
      },
    });
  })
);

/**
 * POST /api/portfolios
 * Create new portfolio position
 *
 * Request body:
 * {
 *   "symbol": "NVDA",
 *   "assetType": "stock",
 *   "exchange": "NASDAQ",
 *   "shares": 100,
 *   "avgCost": 880.00,
 *   "alerts": {
 *     "priceAbove": 900,
 *     "priceBelow": 800
 *   }
 * }
 */
router.post(
  '/',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const validation = validatePortfolio(req.body);

    if (!validation.valid) {
      throw new ValidationError(validation.errors);
    }

    const portfolio = await createPortfolio(req.userId, req.body);

    logger.info('Portfolio created via API', {
      portfolioId: portfolio.id,
      userId: req.userId,
      symbol: portfolio.symbol,
    });

    return res.success(
      {
        portfolio: {
          id: portfolio.id,
          symbol: portfolio.symbol,
          assetType: portfolio.asset_type,
          exchange: portfolio.exchange,
          shares: parseFloat(portfolio.shares),
          avgCost: parseFloat(portfolio.avg_cost),
          currentPrice: portfolio.current_price ? parseFloat(portfolio.current_price) : null,
          unrealizedPnL: portfolio.unrealized_pnl ? parseFloat(portfolio.unrealized_pnl) : null,
          totalValue: portfolio.total_value ? parseFloat(portfolio.total_value) : null,
          openedAt: portfolio.opened_at,
          alerts: portfolio.alerts,
          status: portfolio.status,
          createdAt: portfolio.created_at,
        },
      },
      201
    );
  })
);

/**
 * PUT /api/portfolios/:id
 * Update portfolio position
 *
 * Request body:
 * {
 *   "shares": 150,
 *   "avgCost": 870.00,
 *   "alerts": {...},
 *   "status": "active"
 * }
 */
router.put(
  '/:id',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const portfolio = await updatePortfolio(req.params.id, req.userId, req.body);

    logger.info('Portfolio updated via API', {
      portfolioId: portfolio.id,
      userId: req.userId,
      updates: Object.keys(req.body),
    });

    return res.success({
      portfolio: {
        id: portfolio.id,
        symbol: portfolio.symbol,
        assetType: portfolio.asset_type,
        exchange: portfolio.exchange,
        shares: parseFloat(portfolio.shares),
        avgCost: parseFloat(portfolio.avg_cost),
        currentPrice: portfolio.current_price ? parseFloat(portfolio.current_price) : null,
        unrealizedPnL: portfolio.unrealized_pnl ? parseFloat(portfolio.unrealized_pnl) : null,
        totalValue: portfolio.total_value ? parseFloat(portfolio.total_value) : null,
        openedAt: portfolio.opened_at,
        lastUpdated: portfolio.last_updated,
        alerts: portfolio.alerts,
        status: portfolio.status,
        updatedAt: portfolio.updated_at,
      },
    });
  })
);

/**
 * DELETE /api/portfolios/:id
 * Delete portfolio position
 */
router.delete(
  '/:id',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    await deletePortfolio(req.params.id, req.userId);

    logger.info('Portfolio deleted via API', {
      portfolioId: req.params.id,
      userId: req.userId,
    });

    return res.success({
      message: 'Portfolio position deleted successfully',
    });
  })
);

export default router;
