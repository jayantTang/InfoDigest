/**
 * Market Events Scheduler
 * Collects recent market events and generates LLM-powered digests
 * Sends push notifications hourly to iOS devices
 */

import cron from 'node-cron';
import { pool } from '../config/database.js';
import { sendMessagePush } from './pushService.js';
import { callLLM } from './llmProcessor.js';
import logger from '../config/logger.js';
import config from '../config/index.js';

/**
 * Fetch recent market events from database
 */
async function fetchRecentEvents(hours = 1, minScore = 60) {
  try {
    const query = `
      SELECT
        id, title, description, source, url,
        category, importance_score, symbols, sectors,
        published_at, fetched_at
      FROM news_events
      WHERE importance_score >= $1
        AND published_at >= NOW() - INTERVAL '${hours} hours'
        AND is_processed = false
      ORDER BY importance_score DESC, published_at DESC
      LIMIT 50
    `;

    const result = await pool.query(query, [minScore]);

    logger.info('Fetched recent market events', {
      count: result.rows.length,
      hours,
      minScore,
    });

    return result.rows;
  } catch (error) {
    logger.error('Failed to fetch recent events', {
      error: error.message,
      hours,
      minScore,
    });
    throw error;
  }
}

/**
 * Format events data for LLM prompt
 */
function formatEventsData(events) {
  if (!events || events.length === 0) {
    return '暂无重要市场事件';
  }

  let text = `## 市场事件列表 (共${events.length}个)\n\n`;

  // Group by category
  const categories = {
    earnings: { name: '💰 财报', events: [] },
    merger: { name: '🤝 并购', events: [] },
    product: { name: '📦 产品', events: [] },
    regulation: { name: '⚖️ 监管', events: [] },
    macro: { name: '🌍 宏观', events: [] },
    other: { name: '📰 其他', events: [] },
  };

  events.forEach((event) => {
    const category = event.category || 'other';
    if (categories[category]) {
      categories[category].events.push(event);
    } else {
      categories.other.events.push(event);
    }
  });

  // Format each category
  Object.entries(categories).forEach(([key, { name, events: categoryEvents }]) => {
    if (categoryEvents.length > 0) {
      text += `### ${name}\n\n`;
      categoryEvents.forEach((event, index) => {
        text += `${index + 1}. **${event.title}**\n`;
        if (event.description) {
          text += `   ${event.description}\n`;
        }
        if (event.symbols && event.symbols.length > 0) {
          text += `   相关股票: ${event.symbols.join(', ')}\n`;
        }
        if (event.importance_score) {
          text += `   重要性: ${event.importance_score}/100\n`;
        }
        text += '\n';
      });
    }
  });

  return text;
}

/**
 * Generate events digest using LLM
 */
async function generateEventsDigest(events) {
  if (!config.apiKeys.deepseek && !config.apiKeys.openai) {
    logger.warn('LLM not configured, using fallback digest');
    return generateFallbackDigest(events);
  }

  try {
    const eventsData = formatEventsData(events);
    const now = new Date();
    const timeRange = `${now.getHours() - 1}:00 - ${now.getHours()}:00`;

    const systemPrompt = `你是一个专业的市场分析师。请将以下市场事件整理成简洁的摘要。

要求：
1. 按类别分组展示（财报、并购、产品、监管、宏观、其他）
2. 每个类别选择2-3个最重要的事件
3. 使用简洁的语言，适合移动端阅读
4. 标注相关股票代码
5. 使用表情符号增加可读性
6. 保留关键信息，避免过度简化

请以JSON格式返回，包含以下字段：
- title: 市场事件摘要标题（包含时间范围）
- summary: 1-2句话的推送通知摘要
- content: 完整的markdown格式摘要
- eventCount: 事件总数
- categories: 事件类别列表
- topSymbols: 最受关注的股票代码列表（前5个）

保持内容简洁但信息丰富。`;

    const userPrompt = `请整理以下市场事件，时间范围：${timeRange}\n\n${eventsData}`;

    logger.info('Calling LLM for events digest');
    const responseText = await callLLM(systemPrompt, userPrompt, 2000);
    const result = JSON.parse(responseText);

    logger.info('Events digest generated successfully', {
      title: result.title,
      eventCount: result.eventCount,
      contentLength: result.content?.length,
    });

    return {
      ...result,
      messageType: 'market_events',
      generatedAt: now.toISOString(),
    };
  } catch (error) {
    logger.error('LLM events digest generation failed', {
      error: error.message,
    });
    // Fall back to simple digest
    return generateFallbackDigest(events);
  }
}

/**
 * Generate fallback digest without LLM
 */
function generateFallbackDigest(events) {
  const now = new Date();
  const timeRange = `${now.getHours() - 1}:00 - ${now.getHours()}:00`;

  // Count by category
  const categoryCount = {};
  const allSymbols = new Set();

  events.forEach((event) => {
    const category = event.category || 'other';
    categoryCount[category] = (categoryCount[category] || 0) + 1;

    if (event.symbols) {
      event.symbols.forEach((symbol) => allSymbols.add(symbol));
    }
  });

  // Build simple content
  let content = `# 市场事件摘要 (${timeRange})\n\n`;

  Object.entries(categoryCount).forEach(([category, count]) => {
    const categoryNames = {
      earnings: '💰 财报',
      merger: '🤝 并购',
      product: '📦 产品',
      regulation: '⚖️ 监管',
      macro: '🌍 宏观',
      other: '📰 其他',
    };
    content += `${categoryNames[category] || category}: ${count}个事件\n`;
  });

  content += `\n## 事件列表\n\n`;
  events.slice(0, 10).forEach((event, index) => {
    content += `${index + 1}. **${event.title}**`;
    if (event.symbols && event.symbols.length > 0) {
      content += ` (${event.symbols.join(', ')})`;
    }
    content += '\n';
  });

  const topSymbols = Array.from(allSymbols).slice(0, 5);

  return {
    title: `市场事件摘要 - ${timeRange}`,
    summary: `本小时共${events.length}个重要市场事件`,
    content,
    eventCount: events.length,
    categories: Object.keys(categoryCount),
    topSymbols,
    messageType: 'market_events',
    generatedAt: now.toISOString(),
  };
}

/**
 * Mark events as processed
 */
async function markEventsProcessed(eventIds) {
  if (!eventIds || eventIds.length === 0) {
    return;
  }

  try {
    const query = `
      UPDATE news_events
      SET is_processed = true
      WHERE id = ANY($1)
    `;

    await pool.query(query, [eventIds]);

    logger.info('Marked events as processed', { count: eventIds.length });
  } catch (error) {
    logger.error('Failed to mark events as processed', {
      error: error.message,
    });
  }
}

/**
 * Main digest generation and push cycle
 */
async function runEventsCycle() {
  const startTime = Date.now();
  logger.info('=== Starting market events cycle ===');

  try {
    // Step 1: Fetch recent events
    logger.info('Step 1: Fetching recent market events...');
    const minScore = config.marketEvents?.minScore || 60;
    const hours = config.marketEvents?.hours || 1;

    const events = await fetchRecentEvents(hours, minScore);

    if (events.length === 0) {
      logger.info('No significant market events in the last hour, skipping');
      return {
        success: true,
        message: 'No events to process',
      };
    }

    // Step 2: Generate digest with LLM
    logger.info('Step 2: Generating events digest with LLM...');
    const digest = await generateEventsDigest(events);

    // Step 3: Save to database
    logger.info('Step 3: Saving message to database...');
    const messageResult = await pool.query(
      `INSERT INTO messages (
        message_type, title, content_rich, summary,
        images, links, source_data
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *`,
      [
        'market_events',
        digest.title,
        digest.content,
        digest.summary,
        JSON.stringify([]),
        JSON.stringify([]),
        JSON.stringify({
          eventCount: digest.eventCount,
          categories: digest.categories,
          topSymbols: digest.topSymbols,
          generatedAt: digest.generatedAt,
        }),
      ]
    );

    const message = messageResult.rows[0];
    logger.info('Message saved', { messageId: message.id, title: digest.title });

    // Step 4: Send push notifications
    logger.info('Step 4: Sending push notifications...');
    const pushResults = await sendMessagePush(message);

    // Step 5: Mark events as processed
    logger.info('Step 5: Marking events as processed...');
    const eventIds = events.map((e) => e.id);
    await markEventsProcessed(eventIds);

    const duration = Date.now() - startTime;
    logger.info('=== Market events cycle completed ===', {
      messageId: message.id,
      eventCount: events.length,
      pushSuccess: pushResults.success,
      pushFailed: pushResults.failed,
      durationMs: duration,
    });

    return {
      success: true,
      messageId: message.id,
      eventCount: events.length,
      pushResults,
    };
  } catch (error) {
    const duration = Date.now() - startTime;
    logger.error('Market events cycle failed', {
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
 * Market Events Scheduler Class
 */
export class MarketEventsScheduler {
  constructor(schedule) {
    this.schedule = schedule || '0 * * * *'; // Hourly by default
    this.task = null;
  }

  /**
   * Start the scheduler
   * @param {boolean} runImmediately - Run immediately on start (default: true)
   */
  start(runImmediately = true) {
    if (this.task) {
      logger.warn('Market events scheduler already running');
      return;
    }

    logger.info('Starting market events scheduler', { schedule: this.schedule });

    // Run immediately on startup
    if (runImmediately) {
      logger.info('Running initial market events cycle...');
      this.runTask().catch((error) => {
        logger.error('Initial cycle failed', { error: error.message });
      });
    }

    // Schedule recurring task
    this.task = cron.schedule(this.schedule, () => {
      this.runTask().catch((error) => {
        logger.error('Scheduled cycle failed', { error: error.message });
      });
    });

    logger.info('Market events scheduler started');
  }

  /**
   * Run a single cycle
   */
  async runTask() {
    logger.info('Market events cycle triggered');
    return await runEventsCycle();
  }

  /**
   * Stop the scheduler
   */
  stop() {
    if (this.task) {
      this.task.stop();
      this.task = null;
      logger.info('Market events scheduler stopped');
    }
  }

  /**
   * Run a one-time cycle
   */
  async runOnce() {
    return await runEventsCycle();
  }
}

export default {
  MarketEventsScheduler,
  runEventsCycle,
  fetchRecentEvents,
  generateEventsDigest,
};
