import logger from '../config/logger.js';
import { AppError } from './errorHandler.js';

/**
 * Simple in-memory rate limiter
 * For production, use Redis-based rate limiting
 */
class RateLimiter {
  constructor(options = {}) {
    this.windowMs = options.windowMs || 60000; // 1 minute default
    this.maxRequests = options.maxRequests || 100;
    this.requests = new Map();
    this.cleanupInterval = setInterval(() => this.cleanup(), this.windowMs);
  }

  cleanup() {
    const now = Date.now();
    for (const [key, data] of this.requests.entries()) {
      if (now - data.resetTime > this.windowMs) {
        this.requests.delete(key);
      }
    }
  }

  check(identifier) {
    const now = Date.now();
    const record = this.requests.get(identifier);

    if (!record || now > record.resetTime) {
      // Create new record
      this.requests.set(identifier, {
        count: 1,
        resetTime: now + this.windowMs,
      });
      return { allowed: true, remaining: this.maxRequests - 1 };
    }

    if (record.count >= this.maxRequests) {
      return {
        allowed: false,
        remaining: 0,
        resetTime: record.resetTime,
      };
    }

    record.count++;
    return {
      allowed: true,
      remaining: this.maxRequests - record.count,
      resetTime: record.resetTime,
    };
  }

  stop() {
    clearInterval(this.cleanupInterval);
  }
}

/**
 * Rate limiting middleware
 */
export const createRateLimiter = (options = {}) => {
  const limiter = new RateLimiter(options);

  return (req, res, next) => {
    const identifier = req.ip || req.connection.remoteAddress;
    const result = limiter.check(identifier);

    if (!result.allowed) {
      logger.warn('Rate limit exceeded', {
        ip: identifier,
        path: req.path,
      });

      res.setHeader('X-RateLimit-Limit', options.maxRequests);
      res.setHeader('X-RateLimit-Remaining', 0);
      const resetDate = new Date(result.resetTime);
      if (!isNaN(resetDate.getTime())) {
        res.setHeader('X-RateLimit-Reset', resetDate.toISOString());
      }

      throw new AppError('Too many requests', 429);
    }

    res.setHeader('X-RateLimit-Limit', options.maxRequests);
    res.setHeader('X-RateLimit-Remaining', result.remaining);
    const resetDate = new Date(result.resetTime);
    if (!isNaN(resetDate.getTime())) {
      res.setHeader('X-RateLimit-Reset', resetDate.toISOString());
    }

    next();
  };
};

// Predefined limiters
export const apiLimiter = createRateLimiter({
  windowMs: 60000, // 1 minute
  maxRequests: 100,
});

export const authLimiter = createRateLimiter({
  windowMs: 900000, // 15 minutes
  maxRequests: 5, // Strict limit for auth operations
});

export const adminLimiter = createRateLimiter({
  windowMs: 60000, // 1 minute
  maxRequests: 20, // Stricter for admin endpoints
});
