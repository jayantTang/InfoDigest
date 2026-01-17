import logger from '../config/logger.js';
import { AppError } from './errorHandler.js';

/**
 * API Key authentication middleware
 * Protects admin and sensitive endpoints
 */
export const requireApiKey = (req, res, next) => {
  const apiKey = req.headers['x-api-key'];

  if (!apiKey) {
    throw new AppError('API key is required', 401);
  }

  const validApiKeys = process.env.ADMIN_API_KEYS?.split(',') || [];

  if (!validApiKeys.includes(apiKey)) {
    logger.warn('Invalid API key attempt', {
      ip: req.ip,
      path: req.path,
    });
    throw new AppError('Invalid API key', 403);
  }

  req.apiKey = apiKey;
  next();
};

/**
 * Device authentication middleware
 * Validates device token for device-specific operations
 */
export const requireDeviceToken = (req, res, next) => {
  const deviceToken = req.headers['x-device-token'];

  if (!deviceToken) {
    throw new AppError('Device token is required', 401);
  }

  req.deviceToken = deviceToken;
  next();
};

/**
 * Optional authentication - doesn't throw error
 * Used for endpoints that work with or without auth
 */
export const optionalAuth = (req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  const validApiKeys = process.env.ADMIN_API_KEYS?.split(',') || [];

  if (apiKey && validApiKeys.includes(apiKey)) {
    req.apiKey = apiKey;
    req.isAuthenticated = true;
  } else {
    req.isAuthenticated = false;
  }

  next();
};
