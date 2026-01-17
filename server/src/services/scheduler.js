import cron from 'node-cron';
import { fetchAllData } from './dataFetcher.js';
import { generateDigest, generateNewsDigest, generateStockSummary } from './llmProcessor.js';
import { sendMessagePush } from './pushService.js';
import { query } from '../config/database.js';
import logger from '../config/logger.js';

/**
 * Main digest generation task
 * Runs every hour to fetch data, process with LLM, and send push notifications
 */
async function generateAndSendDigest() {
  const startTime = Date.now();
  logger.info('=== Starting digest generation cycle ===');

  try {
    // Step 1: Fetch data from all sources
    logger.info('Step 1: Fetching data...');
    const data = await fetchAllData();

    if (!data.news && !data.stocks) {
      logger.warn('No data fetched, skipping digest generation');
      return;
    }

    // Step 2: Process with LLM
    logger.info('Step 2: Processing with LLM...');
    let digest;
    let messageType = 'digest';

    if (data.news && data.stocks) {
      // Full digest with both news and stocks
      digest = await generateDigest(data.news, data.stocks);
      messageType = 'digest';
    } else if (data.news) {
      // News only
      digest = await generateNewsDigest(data.news);
      messageType = 'news';
    } else if (data.stocks) {
      // Stocks only
      digest = await generateStockSummary(data.stocks);
      messageType = 'stock';
    }

    // Step 3: Save message to database
    logger.info('Step 3: Saving message to database...');
    const messageResult = await query(
      `INSERT INTO messages (
        message_type, title, content_rich, summary,
        images, links, source_data
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *`,
      [
        messageType,
        digest.title,
        digest.content,
        digest.summary,
        JSON.stringify(digest.images || []),
        JSON.stringify(digest.links || []),
        JSON.stringify({ news: data.news, stocks: data.stocks, generated: digest.generatedAt }),
      ]
    );

    const message = messageResult.rows[0];
    logger.info('Message saved', { messageId: message.id, title: digest.title });

    // Step 4: Send push notifications
    logger.info('Step 4: Sending push notifications...');
    const pushResults = await sendMessagePush(message);

    const duration = Date.now() - startTime;
    logger.info('=== Digest cycle completed ===', {
      messageId: message.id,
      messageType,
      pushSuccess: pushResults.success,
      pushFailed: pushResults.failed,
      durationMs: duration,
    });

    return {
      success: true,
      messageId: message.id,
      pushResults,
    };
  } catch (error) {
    const duration = Date.now() - startTime;
    logger.error('Digest generation failed', {
      error: error.message,
      stack: error.stack,
      durationMs: duration,
    });

    return {
      success: false,
      error: error.message,
    };
  }
}

/**
 * Test task - generates a digest without sending push
 */
async function testDigestGeneration() {
  logger.info('Running test digest generation...');

  try {
    const data = await fetchAllData();

    let digest;
    if (data.news && data.stocks) {
      digest = await generateDigest(data.news, data.stocks);
    } else if (data.news) {
      digest = await generateNewsDigest(data.news);
    } else if (data.stocks) {
      digest = await generateStockSummary(data.stocks);
    }

    logger.info('Test digest generated', {
      title: digest.title,
      contentLength: digest.content?.length,
    });

    return digest;
  } catch (error) {
    logger.error('Test digest failed', { error: error.message });
    throw error;
  }
}

/**
 * Initialize and start the scheduler
 */
export class TaskScheduler {
  constructor(schedule) {
    this.schedule = schedule;
    this.task = null;
  }

  start() {
    if (this.task) {
      logger.warn('Scheduler already running');
      return;
    }

    logger.info('Starting task scheduler', { schedule: this.schedule });

    // Run immediately on startup
    this.runTask();

    // Schedule recurring task
    this.task = cron.schedule(this.schedule, () => {
      this.runTask();
    });

    logger.info('Task scheduler started');
  }

  async runTask() {
    logger.info('Scheduled task triggered');
    await generateAndSendDigest();
  }

  stop() {
    if (this.task) {
      this.task.stop();
      this.task = null;
      logger.info('Task scheduler stopped');
    }
  }

  // Run a one-time digest generation
  async runOnce() {
    return await generateAndSendDigest();
  }

  // Test mode - generate without pushing
  async test() {
    return await testDigestGeneration();
  }
}

export default TaskScheduler;
