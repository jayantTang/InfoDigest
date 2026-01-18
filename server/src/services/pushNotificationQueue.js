/**
 * Push Notification Queue for v2.0
 * Manages push notification delivery with priority queue and deduplication
 */

import logger from '../config/logger.js';
import { pool } from '../config/database.js';

class PushNotificationQueue {
  constructor() {
    this.queue = [];
    this.isProcessing = false;
    this.processingInterval = 5000; // Process every 5 seconds
    this.intervalId = null;
    this.deduplicationWindow = 300000; // 5 minutes deduplication window
    this.sentNotifications = new Map(); // For deduplication
  }

  /**
   * Start the queue processor
   */
  start() {
    if (this.isProcessing) {
      logger.warn('Push notification queue already processing');
      return;
    }

    logger.info('Starting push notification queue');

    this.isProcessing = true;

    // Process queue periodically
    this.intervalId = setInterval(async () => {
      try {
        await this.processQueue();
      } catch (error) {
        logger.error('Queue processing failed', {
          error: error.message,
          stack: error.stack,
        });
      }
    }, this.processingInterval);

    logger.info('Push notification queue started', {
      processingInterval: this.processingInterval,
    });
  }

  /**
   * Stop the queue processor
   */
  stop() {
    if (!this.isProcessing) {
      logger.warn('Push notification queue not processing');
      return;
    }

    logger.info('Stopping push notification queue');

    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }

    this.isProcessing = false;

    logger.info('Push notification queue stopped');
  }

  /**
   * Add a notification to the queue
   * @param {Object} notification - Notification object
   * @param {string} notification.userId - User ID
   * @param {string} notification.title - Notification title
   * @param {string} notification.message - Notification message
   * @param {number} notification.priority - Priority (0-100, higher is more important)
   * @param {Object} notification.data - Additional data
   * @param {string} notification.type - Type (strategy_trigger, market_event, focus_alert, etc.)
   */
  async enqueue(notification) {
    try {
      // Validate required fields
      if (!notification.userId || !notification.title || !notification.message) {
        throw new Error('Missing required fields: userId, title, message');
      }

      // Generate deduplication key
      const dedupeKey = this.generateDedupeKey(notification);

      // Check if recently sent similar notification
      if (this.isDuplicate(dedupeKey)) {
        logger.debug('Duplicate notification skipped', {
          dedupeKey,
          userId: notification.userId,
        });
        return {
          success: false,
          reason: 'duplicate',
          dedupeKey,
        };
      }

      // Add to queue with timestamp
      const queueItem = {
        id: this.generateId(),
        ...notification,
        priority: notification.priority || 50,
        createdAt: new Date(),
        attempts: 0,
        dedupeKey,
      };

      this.queue.push(queueItem);

      // Sort queue by priority (higher priority first)
      this.sortQueue();

      logger.info('Notification queued', {
        id: queueItem.id,
        userId: notification.userId,
        type: notification.type,
        priority: queueItem.priority,
        queueSize: this.queue.length,
      });

      return {
        success: true,
        notificationId: queueItem.id,
        queuePosition: this.getQueuePosition(queueItem.id),
      };
    } catch (error) {
      logger.error('Failed to enqueue notification', {
        error: error.message,
        notification,
      });
      throw error;
    }
  }

  /**
   * Process the notification queue
   */
  async processQueue() {
    if (this.queue.length === 0) {
      return;
    }

    logger.debug('Processing notification queue', {
      queueSize: this.queue.length,
    });

    // Get batch of notifications (top 10)
    const batch = this.queue.splice(0, Math.min(10, this.queue.length));

    for (const notification of batch) {
      try {
        await this.sendNotification(notification);

        // Record as sent for deduplication
        this.recordSent(notification);

        logger.info('Notification sent successfully', {
          id: notification.id,
          userId: notification.userId,
          type: notification.type,
        });
      } catch (error) {
        logger.error('Failed to send notification', {
          id: notification.id,
          userId: notification.userId,
          error: error.message,
        });

        // Retry logic
        notification.attempts++;

        if (notification.attempts < 3) {
          // Re-queue for retry
          this.queue.push(notification);
          this.sortQueue();
        } else {
          // Max retries reached, log and discard
          logger.error('Notification max retries exceeded', {
            id: notification.id,
            userId: notification.userId,
            attempts: notification.attempts,
          });
        }
      }
    }
  }

  /**
   * Send a push notification
   */
  async sendNotification(notification) {
    try {
      // Get user's push tokens
      const query = `
        SELECT device_token, user_id
        FROM devices
        WHERE user_id = $1
          AND is_active = true
          AND device_token IS NOT NULL
      `;

      const result = await pool.query(query, [notification.userId]);
      const devices = result.rows;

      if (devices.length === 0) {
        throw new Error('No active devices found for user');
      }

      // Import push service dynamically to avoid circular dependency
      const { apnsProvider } = await import('./pushService.js');

      // Prepare notification payload
      const notificationPayload = {
        title: notification.title,
        body: notification.message,
        badge: 1,
        data: notification.data || {},
      };

      // Send to all user devices using sendToMultipleDevices for efficiency
      const deviceTokens = devices.map((d) => d.device_token);

      await apnsProvider.sendToMultipleDevices(deviceTokens, notificationPayload);

      // Log push notification
      await this.logPushNotification(notification, devices.length);

      return {
        success: true,
        devicesCount: devices.length,
      };
    } catch (error) {
      logger.error('Push notification send failed', {
        error: error.message,
        notificationId: notification.id,
      });
      throw error;
    }
  }

  /**
   * Log push notification to database
   */
  async logPushNotification(notification, devicesCount) {
    try {
      const query = `
        INSERT INTO push_logs (
          device_token,
          user_id,
          payload,
          status,
          sent_at
        ) VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
      `;

      // Log for each device
      for (let i = 0; i < devicesCount; i++) {
        await pool.query(query, [
          'multiple', // Indicates multiple devices
          notification.userId,
          JSON.stringify({
            title: notification.title,
            message: notification.message,
            type: notification.type,
            priority: notification.priority,
            data: notification.data,
          }),
          'sent',
        ]);
      }
    } catch (error) {
      logger.error('Failed to log push notification', {
        error: error.message,
      });
    }
  }

  /**
   * Generate deduplication key
   * Prevents sending similar notifications within the deduplication window
   */
  generateDedupeKey(notification) {
    // Key based on user, type, and relevant content
    const parts = [
      notification.userId,
      notification.type,
    ];

    // Add symbol if present
    if (notification.data?.symbol) {
      parts.push(notification.data.symbol);
    }

    // Add strategy ID if present
    if (notification.data?.strategyId) {
      parts.push(notification.data.strategyId);
    }

    return parts.join(':');
  }

  /**
   * Check if notification is a duplicate
   */
  isDuplicate(dedupeKey) {
    const lastSent = this.sentNotifications.get(dedupeKey);
    if (!lastSent) {
      return false;
    }

    const timeSinceLastSent = Date.now() - lastSent;
    return timeSinceLastSent < this.deduplicationWindow;
  }

  /**
   * Record notification as sent
   */
  recordSent(notification) {
    if (notification.dedupeKey) {
      this.sentNotifications.set(notification.dedupeKey, Date.now());

      // Cleanup old entries
      this.cleanupDedupeCache();
    }
  }

  /**
   * Cleanup old deduplication cache entries
   */
  cleanupDedupeCache() {
    const now = Date.now();
    for (const [key, timestamp] of this.sentNotifications.entries()) {
      if (now - timestamp > this.deduplicationWindow) {
        this.sentNotifications.delete(key);
      }
    }
  }

  /**
   * Sort queue by priority
   */
  sortQueue() {
    this.queue.sort((a, b) => {
      // Higher priority first
      if (b.priority !== a.priority) {
        return b.priority - a.priority;
      }
      // If same priority, older first
      return a.createdAt - b.createdAt;
    });
  }

  /**
   * Get queue position for a notification ID
   */
  getQueuePosition(notificationId) {
    return this.queue.findIndex((item) => item.id === notificationId) + 1;
  }

  /**
   * Generate unique ID
   */
  generateId() {
    return `push_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Get queue status
   */
  getStatus() {
    return {
      queueSize: this.queue.length,
      isProcessing: this.isProcessing,
      deduplicationCacheSize: this.sentNotifications.size,
      processingInterval: this.processingInterval,
    };
  }

  /**
   * Get pending notifications
   */
  getPendingNotifications(userId = null) {
    let pending = this.queue;

    if (userId) {
      pending = pending.filter((n) => n.userId === userId);
    }

    return pending.map((n) => ({
      id: n.id,
      type: n.type,
      priority: n.priority,
      createdAt: n.createdAt,
      attempts: n.attempts,
    }));
  }

  /**
   * Clear the queue
   */
  clearQueue() {
    const count = this.queue.length;
    this.queue = [];
    logger.info('Notification queue cleared', { count });
    return { cleared: count };
  }
}

// Singleton instance
const pushNotificationQueue = new PushNotificationQueue();

export default pushNotificationQueue;
