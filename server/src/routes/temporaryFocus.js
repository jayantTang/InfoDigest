/**
 * Temporary Focus Routes for v2.0
 * Handles temporary focus CRUD operations
 */

import express from 'express';
import {
  getUserTemporaryFocus,
  getTemporaryFocusById,
  createTemporaryFocus,
  updateTemporaryFocus,
  deleteTemporaryFocus,
} from '../services/temporaryFocusService.js';
import { requireDeviceToken, requireUser } from '../middleware/auth.js';
import { responseHelpers } from '../middleware/responseFormatter.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { validateTemporaryFocus, ValidationError } from '../utils/validators.js';
import logger from '../config/logger.js';

const router = express.Router();

// Apply response helpers middleware
router.use(responseHelpers);

/**
 * GET /api/temporary-focus
 * Get all temporary focus items for current user
 * Query params: ?status=monitoring
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

    const focusItems = await getUserTemporaryFocus(req.userId, filters);

    return res.success({
      temporaryFocus: focusItems.map((f) => ({
        id: f.id,
        title: f.title,
        description: f.description,
        targets: f.targets,
        focus: f.focus,
        expiresAt: f.expires_at,
        status: f.status,
        findings: f.findings,
        createdAt: f.created_at,
        updatedAt: f.updated_at,
      })),
    });
  })
);

/**
 * GET /api/temporary-focus/:id
 * Get specific temporary focus item by ID
 */
router.get(
  '/:id',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const focusItem = await getTemporaryFocusById(req.params.id, req.userId);

    if (!focusItem) {
      return res.error('Temporary focus item not found', 404);
    }

    return res.success({
      temporaryFocus: {
        id: focusItem.id,
        title: focusItem.title,
        description: focusItem.description,
        targets: focusItem.targets,
        focus: focusItem.focus,
        expiresAt: focusItem.expires_at,
        status: focusItem.status,
        findings: focusItem.findings,
        createdAt: focusItem.created_at,
        updatedAt: focusItem.updated_at,
      },
    });
  })
);

/**
 * POST /api/temporary-focus
 * Create new temporary focus
 *
 * Request body:
 * {
 *   "title": "关注AMD财报对NVDA的影响",
 *   "description": "AMD发布财报，观察对NVDA股价的影响",
 *   "targets": [
 *     {"symbol": "AMD", "type": "stock"},
 *     {"symbol": "NVDA", "type": "stock"}
 *   ],
 *   "focus": {
 *     "newsImpact": true,
 *     "priceReaction": true,
 *     "correlation": true,
 *     "sectorEffect": false
 *   },
 *   "expiresAt": "2024-02-01T23:59:59Z"
 * }
 */
router.post(
  '/',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const validation = validateTemporaryFocus(req.body);

    if (!validation.valid) {
      throw new ValidationError(validation.errors);
    }

    const focusItem = await createTemporaryFocus(req.userId, req.body);

    logger.info('Temporary focus created via API', {
      focusId: focusItem.id,
      userId: req.userId,
      title: focusItem.title,
    });

    return res.success(
      {
        temporaryFocus: {
          id: focusItem.id,
          title: focusItem.title,
          description: focusItem.description,
          targets: focusItem.targets,
          focus: focusItem.focus,
          expiresAt: focusItem.expires_at,
          status: focusItem.status,
          createdAt: focusItem.created_at,
        },
      },
      201
    );
  })
);

/**
 * PUT /api/temporary-focus/:id
 * Update temporary focus
 *
 * Request body:
 * {
 *   "title": "Updated title",
 *   "status": "extended",
 *   "expiresAt": "2024-02-02T23:59:59Z",
 *   "findings": {
 *     "summary": "AMD财报超预期，NVDA股价上涨3%"
 *   }
 * }
 */
router.put(
  '/:id',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const focusItem = await updateTemporaryFocus(
      req.params.id,
      req.userId,
      req.body
    );

    logger.info('Temporary focus updated via API', {
      focusId: focusItem.id,
      userId: req.userId,
      updates: Object.keys(req.body),
    });

    return res.success({
      temporaryFocus: {
        id: focusItem.id,
        title: focusItem.title,
        description: focusItem.description,
        targets: focusItem.targets,
        focus: focusItem.focus,
        expiresAt: focusItem.expires_at,
        status: focusItem.status,
        findings: focusItem.findings,
        updatedAt: focusItem.updated_at,
      },
    });
  })
);

/**
 * DELETE /api/temporary-focus/:id
 * Delete temporary focus
 */
router.delete(
  '/:id',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    await deleteTemporaryFocus(req.params.id, req.userId);

    logger.info('Temporary focus deleted via API', {
      focusId: req.params.id,
      userId: req.userId,
    });

    return res.success({
      message: 'Temporary focus deleted successfully',
    });
  })
);

export default router;
