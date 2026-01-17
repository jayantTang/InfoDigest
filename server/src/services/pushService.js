import apn from '@parse/node-apn';
import config from '../config/index.js';
import logger from '../config/logger.js';
import { query } from '../config/database.js';

/**
 * APNs Provider
 */
class APNsProvider {
  constructor() {
    this.provider = null;
    this.initialize();
  }

  initialize() {
    try {
      const options = {
        token: {
          key: config.apns.keyPath,
          keyId: config.apns.keyId,
          teamId: config.apns.teamId,
        },
        production: config.apns.production,
      };

      this.provider = new apn.Provider(options);
      logger.info('APNs provider initialized', {
        production: config.apns.production,
        bundleId: config.apns.bundleId,
      });
    } catch (error) {
      logger.error('Failed to initialize APNs provider', { error: error.message });
    }
  }

  /**
   * Send push notification to a single device
   */
  async sendToDevice(deviceToken, notification) {
    if (!this.provider) {
      throw new Error('APNs provider not initialized');
    }

    const note = new apn.Notification({
      aps: {
        alert: {
          title: notification.title,
          body: notification.summary || notification.body,
        },
        sound: 'default',
        badge: notification.badge || 1,
        'mutable-content': 1,
        category: notification.category || 'MESSAGE',
      },
      ...notification.payload,
    });

    note.topic = config.apns.bundleId;

    try {
      const result = await this.provider.send(note, deviceToken);

      if (result.failed && result.failed.length > 0) {
        const error = result.failed[0];
        if (error.response) {
          // Handle specific error codes
          if (error.response.statusCode === 410) {
            // Device token is no longer valid
            logger.warn('Device token invalid, marking as inactive', { deviceToken });
            await this.deactivateDevice(deviceToken);
          }
          throw new Error(`APNs error: ${error.response.reason}`);
        }
        throw new Error('Push notification failed');
      }

      logger.info('Push notification sent successfully', {
        deviceToken: deviceToken.substring(0, 20) + '...',
        title: notification.title,
      });

      return { success: true, sent: result.sent.length };
    } catch (error) {
      logger.error('Failed to send push notification', {
        error: error.message,
        deviceToken: deviceToken.substring(0, 20) + '...',
      });
      throw error;
    }
  }

  /**
   * Send push notification to multiple devices
   */
  async sendToMultipleDevices(deviceTokens, notification) {
    const results = {
      success: 0,
      failed: 0,
      errors: [],
    };

    // Process in batches
    const batchSize = 20;
    for (let i = 0; i < deviceTokens.length; i += batchSize) {
      const batch = deviceTokens.slice(i, i + batchSize);

      await Promise.allSettled(
        batch.map(async (token) => {
          try {
            await this.sendToDevice(token, notification);
            results.success++;
          } catch (error) {
            results.failed++;
            results.errors.push({ token: token.substring(0, 20), error: error.message });
          }
        })
      );
    }

    logger.info('Batch push notification completed', {
      total: deviceTokens.length,
      success: results.success,
      failed: results.failed,
    });

    return results;
  }

  /**
   * Send push notification to all active devices
   */
  async sendToAllDevices(notification) {
    const result = await query(
      'SELECT device_token, id FROM devices WHERE is_active = true AND platform = $1',
      ['ios']
    );

    const deviceTokens = result.rows.map((row) => row.device_token);
    logger.info('Sending push to all iOS devices', { count: deviceTokens.length });

    return await this.sendToMultipleDevices(deviceTokens, notification);
  }

  /**
   * Deactivate a device token
   */
  async deactivateDevice(deviceToken) {
    await query('UPDATE devices SET is_active = false WHERE device_token = $1', [deviceToken]);
  }

  /**
   * Shutdown the provider
   */
  shutdown() {
    if (this.provider) {
      this.provider.shutdown();
      logger.info('APNs provider shut down');
    }
  }
}

// Export singleton instance
export const apnsProvider = new APNsProvider();

/**
 * Send a message as push notification to all devices
 */
export async function sendMessagePush(message) {
  const notification = {
    title: message.title,
    summary: message.summary,
    badge: 1,
    category: message.messageType?.toUpperCase() || 'MESSAGE',
    payload: {
      messageId: message.id,
      type: message.messageType,
    },
  };

  // Send to all devices
  const results = await apnsProvider.sendToAllDevices(notification);

  // Log push results
  const devices = await query(
    'SELECT id FROM devices WHERE is_active = true AND platform = $1',
    ['ios']
  );

  for (const device of devices.rows) {
    const status = results.success > 0 ? 'sent' : 'failed';
    await query(
      `INSERT INTO push_logs (device_id, message_id, status, sent_at)
       VALUES ($1, $2, $3, CURRENT_TIMESTAMP)`,
      [device.id, message.id, status]
    );
  }

  return results;
}

/**
 * Send a test push notification
 */
export async function sendTestPush(title, message) {
  const notification = {
    title: title || 'Test Notification',
    summary: message || 'This is a test push notification from InfoDigest',
    badge: 1,
    category: 'TEST',
    payload: {
      test: true,
    },
  };

  return await apnsProvider.sendToAllDevices(notification);
}
