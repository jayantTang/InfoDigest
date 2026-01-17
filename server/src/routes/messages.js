import express from 'express';
import { query } from '../config/database.js';
import { asyncHandler, AppError } from '../middleware/errorHandler.js';

const router = express.Router();

// Get messages with pagination
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const {
      page = 1,
      limit = 20,
      type,
      userId,
    } = req.query;

    const offset = (page - 1) * limit;

    let queryText = `
      SELECT
        id,
        message_type as "messageType",
        title,
        content_rich as "contentRich",
        summary,
        images,
        links,
        created_at as "createdAt"
      FROM messages
      WHERE 1=1
    `;
    const params = [];
    let paramCount = 0;

    if (type) {
      paramCount++;
      queryText += ` AND message_type = $${paramCount}`;
      params.push(type);
    }

    queryText += ` ORDER BY created_at DESC LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}`;
    params.push(limit, offset);

    const result = await query(queryText, params);

    // Get total count
    let countQuery = 'SELECT COUNT(*) as total FROM messages WHERE 1=1';
    const countParams = [];
    paramCount = 0;

    if (type) {
      paramCount++;
      countQuery += ` AND message_type = $${paramCount}`;
      countParams.push(type);
    }

    const countResult = await query(countQuery, countParams);
    const total = parseInt(countResult.rows[0].total);
    const totalPages = Math.ceil(total / limit);

    res.json({
      success: true,
      data: {
        messages: result.rows,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          totalPages,
        },
      },
    });
  })
);

// Get single message by ID
router.get(
  '/:id',
  asyncHandler(async (req, res) => {
    const { id } = req.params;

    const result = await query(
      `SELECT
        id,
        message_type as "messageType",
        title,
        content_rich as "contentRich",
        content_raw as "contentRaw",
        summary,
        images,
        links,
        source_data as "sourceData",
        created_at as "createdAt",
        sent_at as "sentAt"
       FROM messages
       WHERE id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      throw new AppError('Message not found', 404);
    }

    res.json({ success: true, data: result.rows[0] });
  })
);

// Mark message as read
router.put(
  '/:id/read',
  asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { deviceId } = req.body;

    if (!deviceId) {
      throw new AppError('deviceId is required', 400);
    }

    // Log the read event
    await query(
      `UPDATE push_logs
       SET opened_at = CURRENT_TIMESTAMP
       WHERE message_id = $1 AND device_id = $2
       RETURNING *`,
      [id, deviceId]
    );

    res.json({ success: true, message: 'Message marked as read' });
  })
);

// Get latest messages by type
router.get(
  '/latest/:type',
  asyncHandler(async (req, res) => {
    const { type } = req.params;
    const { limit = 5 } = req.query;

    const result = await query(
      `SELECT
        id,
        message_type as "messageType",
        title,
        summary,
        created_at as "createdAt"
       FROM messages
       WHERE message_type = $1
       ORDER BY created_at DESC
       LIMIT $2`,
      [type, limit]
    );

    res.json({ success: true, data: result.rows });
  })
);

export default router;
