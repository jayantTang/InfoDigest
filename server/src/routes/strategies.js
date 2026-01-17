/**
 * Strategy Routes for v2.0
 * Handles investment strategy CRUD operations
 */

import express from 'express';
import {
  getUserStrategies,
  getStrategyById,
  createStrategy,
  updateStrategy,
  deleteStrategy,
  getStrategyTriggers,
  updateTriggerFeedback,
} from '../services/strategyService.js';
import { requireDeviceToken, requireUser } from '../middleware/auth.js';
import { responseHelpers } from '../middleware/responseFormatter.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { validateStrategy, ValidationError } from '../utils/validators.js';
import logger from '../config/logger.js';

const router = express.Router();

// Apply response helpers middleware
router.use(responseHelpers);

/**
 * GET /api/strategies
 * Get all strategies for current user
 * Query params: ?status=active&symbol=NVDA&conditionType=price
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

    if (req.query.symbol) {
      filters.symbol = req.query.symbol;
    }

    if (req.query.conditionType) {
      filters.conditionType = req.query.conditionType;
    }

    const strategies = await getUserStrategies(req.userId, filters);

    return res.success({
      strategies: strategies.map((s) => ({
        id: s.id,
        name: s.name,
        description: s.description,
        symbol: s.symbol,
        conditionType: s.condition_type,
        conditions: s.conditions,
        action: s.action,
        reasoning: s.reasoning,
        status: s.status,
        priority: s.priority,
        lastTriggeredAt: s.last_triggered_at,
        triggerCount: s.trigger_count,
        createdAt: s.created_at,
        updatedAt: s.updated_at,
      })),
    });
  })
);

/**
 * GET /api/strategies/:id
 * Get specific strategy by ID
 */
router.get(
  '/:id',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const strategy = await getStrategyById(req.params.id, req.userId);

    if (!strategy) {
      return res.error('Strategy not found', 404);
    }

    return res.success({
      strategy: {
        id: strategy.id,
        name: strategy.name,
        description: strategy.description,
        symbol: strategy.symbol,
        conditionType: strategy.condition_type,
        conditions: strategy.conditions,
        action: strategy.action,
        reasoning: strategy.reasoning,
        status: strategy.status,
        priority: strategy.priority,
        lastTriggeredAt: strategy.last_triggered_at,
        triggerCount: strategy.trigger_count,
        createdAt: strategy.created_at,
        updatedAt: strategy.updated_at,
      },
    });
  })
);

/**
 * GET /api/strategies/:id/triggers
 * Get trigger history for a strategy
 */
router.get(
  '/:id/triggers',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const limit = parseInt(req.query.limit) || 10;

    const triggers = await getStrategyTriggers(req.params.id, req.userId, limit);

    return res.success({
      triggers: triggers.map((t) => ({
        id: t.id,
        triggeredAt: t.triggered_at,
        triggerReason: t.trigger_reason,
        marketData: t.market_data,
        userAction: t.user_action,
        userFeedback: t.user_feedback,
        analysisSummary: t.analysis_summary,
      })),
    });
  })
);

/**
 * POST /api/strategies
 * Create new strategy
 *
 * Request body:
 * {
 *   "name": "NVDA突破加仓策略",
 *   "description": "当NVDA突破$900时加仓",
 *   "symbol": "NVDA",
 *   "conditionType": "price",
 *   "conditions": {
 *     "priceAbove": 900,
 *     "volumeIncrease": "20%"
 *   },
 *   "action": {
 *     "type": "buy",
 *     "amount": 20,
 *     "reason": "技术突破确认，上升趋势确立"
 *   },
 *   "reasoning": "NVDA在AI芯片领域领先，突破$900表明市场信心增强",
 *   "priority": 8
 * }
 */
router.post(
  '/',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const validation = validateStrategy(req.body);

    if (!validation.valid) {
      throw new ValidationError(validation.errors);
    }

    const strategy = await createStrategy(req.userId, req.body);

    logger.info('Strategy created via API', {
      strategyId: strategy.id,
      userId: req.userId,
      name: strategy.name,
      symbol: strategy.symbol,
    });

    return res.success(
      {
        strategy: {
          id: strategy.id,
          name: strategy.name,
          description: strategy.description,
          symbol: strategy.symbol,
          conditionType: strategy.condition_type,
          conditions: strategy.conditions,
          action: strategy.action,
          reasoning: strategy.reasoning,
          status: strategy.status,
          priority: strategy.priority,
          createdAt: strategy.created_at,
        },
      },
      201
    );
  })
);

/**
 * PUT /api/strategies/:id
 * Update strategy
 *
 * Request body:
 * {
 *   "name": "Updated name",
 *   "status": "paused",
 *   "priority": 9
 * }
 */
router.put(
  '/:id',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const strategy = await updateStrategy(req.params.id, req.userId, req.body);

    logger.info('Strategy updated via API', {
      strategyId: strategy.id,
      userId: req.userId,
      updates: Object.keys(req.body),
    });

    return res.success({
      strategy: {
        id: strategy.id,
        name: strategy.name,
        description: strategy.description,
        symbol: strategy.symbol,
        conditionType: strategy.condition_type,
        conditions: strategy.conditions,
        action: strategy.action,
        reasoning: strategy.reasoning,
        status: strategy.status,
        priority: strategy.priority,
        lastTriggeredAt: strategy.last_triggered_at,
        triggerCount: strategy.trigger_count,
        updatedAt: strategy.updated_at,
      },
    });
  })
);

/**
 * PUT /api/strategies/triggers/:triggerId/feedback
 * Update trigger with user feedback
 *
 * Request body:
 * {
 *   "action": "executed",
 *   "feedback": "Followed the suggestion and bought 20 shares"
 * }
 */
router.put(
  '/triggers/:triggerId/feedback',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const { action, feedback } = req.body;

    if (!action) {
      return res.error('action is required', 400);
    }

    const trigger = await updateTriggerFeedback(req.params.triggerId, req.userId, {
      action,
      feedback,
    });

    logger.info('Trigger feedback submitted via API', {
      triggerId: req.params.triggerId,
      userId: req.userId,
      action,
    });

    return res.success({
      trigger: {
        id: trigger.id,
        userAction: trigger.user_action,
        userFeedback: trigger.user_feedback,
      },
    });
  })
);

/**
 * DELETE /api/strategies/:id
 * Delete strategy
 */
router.delete(
  '/:id',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    await deleteStrategy(req.params.id, req.userId);

    logger.info('Strategy deleted via API', {
      strategyId: req.params.id,
      userId: req.userId,
    });

    return res.success({
      message: 'Strategy deleted successfully',
    });
  })
);

export default router;
