/**
 * Response Formatter Middleware
 * Standardizes API response format for v2.0
 *
 * Response format:
 * {
 *   "success": true|false,
 *   "data": { ... },  // only on success
 *   "error": "message",  // only on error
 *   "meta": { ... }  // optional pagination/info
 * }
 */

/**
 * Success response helper
 * @param {Object} res - Express response object
 * @param {Object} data - Data to send
 * @param {Number} statusCode - HTTP status code (default: 200)
 * @param {Object} meta - Optional metadata (pagination, etc.)
 */
export const successResponse = (res, data = {}, statusCode = 200, meta = null) => {
  const response = {
    success: true,
    data,
  };

  if (meta) {
    response.meta = meta;
  }

  return res.status(statusCode).json(response);
};

/**
 * Error response helper
 * @param {Object} res - Express response object
 * @param {String} message - Error message
 * @param {Number} statusCode - HTTP status code (default: 400)
 * @param {String} code - Error code for client handling
 */
export const errorResponse = (res, message = 'Error', statusCode = 400, code = null) => {
  const response = {
    success: false,
    error: message,
  };

  if (code) {
    response.errorCode = code;
  }

  return res.status(statusCode).json(response);
};

/**
 * Paginated response helper
 * @param {Object} res - Express response object
 * @param {Array} items - Array of items
 * @param {Object} pagination - Pagination info
 * @param {Object} extra - Extra data to include
 */
export const paginatedResponse = (res, items = [], pagination = {}, extra = {}) => {
  return res.status(200).json({
    success: true,
    data: {
      items,
      ...extra,
    },
    meta: {
      pagination: {
        page: pagination.page || 1,
        limit: pagination.limit || 20,
        total: pagination.total || 0,
        totalPages: Math.ceil((pagination.total || 0) / (pagination.limit || 20)),
        hasMore: (pagination.page || 1) * (pagination.limit || 20) < (pagination.total || 0),
      },
    },
  });
};

/**
 * Middleware to attach response helpers to res object
 */
export const responseHelpers = (req, res, next) => {
  res.success = (data, statusCode, meta) => successResponse(res, data, statusCode, meta);
  res.error = (message, statusCode, code) => errorResponse(res, message, statusCode, code);
  res.paginated = (items, pagination, extra) => paginatedResponse(res, items, pagination, extra);
  next();
};
