import express from 'express';
import cors from 'cors';
import config from './config/index.js';
import logger from './config/logger.js';
import { testConnection } from './config/database.js';
import { errorHandler, notFound } from './middleware/errorHandler.js';
import { requireApiKey } from './middleware/auth.js';
import { apiLimiter, adminLimiter } from './middleware/rateLimiter.js';
import devicesRouter from './routes/devices.js';
import messagesRouter from './routes/messages.js';
import usersRouter from './routes/users.js';
import portfoliosRouter from './routes/portfolios.js';
import watchlistsRouter from './routes/watchlists.js';
import strategiesRouter from './routes/strategies.js';
import temporaryFocusRouter from './routes/temporaryFocus.js';
import dataCollectionRouter from './routes/dataCollection.js';
import monitoringRouter from './routes/monitoring.js';
import analysisRouter from './routes/analysis.js';
import marketEventsRouter from './routes/marketEvents.js';
import economicIndicatorsRouter from './routes/economicIndicators.js';
import historicalChangesRouter from './routes/historicalChanges.js';
import TaskScheduler from './services/scheduler.js';
import { sendTestPush } from './services/pushService.js';
import { initializeDataCollectors } from './services/dataCollectionInit.js';
import monitoringEngine from './services/monitoringEngine.js';
import pushNotificationQueue from './services/pushNotificationQueue.js';
import { MarketEventsScheduler } from './services/marketEventsScheduler.js';

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging
app.use((req, res, next) => {
  logger.info('Incoming request', {
    method: req.method,
    path: req.path,
    ip: req.ip,
  });
  next();
});

// Health check
app.get('/health', async (req, res) => {
  const health = {
    success: true,
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    checks: {
      database: 'unknown',
      redis: 'unknown',
      llm: 'unknown',
    },
  };

  // Check database
  try {
    const dbStatus = await testConnection();
    health.checks.database = dbStatus ? 'ok' : 'error';
  } catch (error) {
    health.checks.database = 'error';
    health.status = 'degraded';
  }

  // Check API keys
  if (config.apiKeys.deepseek || config.apiKeys.openai) {
    health.checks.llm = 'ok';
  } else {
    health.checks.llm = 'missing';
    health.status = 'degraded';
  }

  // Overall status
  const allChecksOk = Object.values(health.checks).every(
    (check) => check === 'ok' || check === 'unknown'
  );
  health.status = allChecksOk ? 'healthy' : 'degraded';

  const statusCode = health.status === 'healthy' ? 200 : 503;
  res.status(statusCode).json(health);
});

// API Routes with rate limiting

// v1.0 routes (backward compatibility)
app.use('/api/devices', apiLimiter, devicesRouter);
app.use('/api/messages', apiLimiter, messagesRouter);

// v2.0 routes
app.use('/api/users', apiLimiter, usersRouter);
app.use('/api/portfolios', apiLimiter, portfoliosRouter);
app.use('/api/watchlists', apiLimiter, watchlistsRouter);
app.use('/api/strategies', apiLimiter, strategiesRouter);
app.use('/api/temporary-focus', apiLimiter, temporaryFocusRouter);
app.use('/api/data-collection', apiLimiter, dataCollectionRouter);
app.use('/api/monitoring', apiLimiter, monitoringRouter);
app.use('/api/analysis', apiLimiter, analysisRouter);
app.use('/api/market-events', apiLimiter, marketEventsRouter);
app.use('/api/economic-indicators', apiLimiter, economicIndicatorsRouter);
app.use('/api/historical-changes', apiLimiter, historicalChangesRouter);

// Admin/Debug routes (protected in all environments)
const adminRouter = express.Router();

adminRouter.post('/test-push', async (req, res, next) => {
  try {
    const { title, message } = req.body;
    const result = await sendTestPush(title, message);
    res.json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
});

adminRouter.post('/run-digest', async (req, res, next) => {
  try {
    const scheduler = req.app.locals.scheduler;
    const result = await scheduler.runOnce();
    res.json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
});

adminRouter.post('/run-market-events', async (req, res, next) => {
  try {
    const marketEventsScheduler = req.app.locals.marketEventsScheduler;
    const result = await marketEventsScheduler.runOnce();
    res.json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
});

// Apply authentication and rate limiting to admin routes
app.use('/api/admin', adminLimiter, requireApiKey, adminRouter);

// Error handling
app.use(notFound);
app.use(errorHandler);

// Initialize server
async function startServer() {
  try {
    // Test database connection
    const dbConnected = await testConnection();
    if (!dbConnected) {
      throw new Error('Database connection failed');
    }

    // Start HTTP server
    const server = app.listen(config.port, () => {
      logger.info(`Server running on port ${config.port}`);
      logger.info(`Environment: ${config.nodeEnv}`);
      logger.info(`API endpoints available at http://localhost:${config.port}/api`);
    });

    // Initialize and start scheduler
    const scheduler = new TaskScheduler(config.cron.schedule);
    scheduler.start();
    app.locals.scheduler = scheduler;

    logger.info(`Scheduler started with cron: ${config.cron.schedule}`);

    // Initialize and start market events scheduler
    const marketEventsSchedule = config.marketEvents?.schedule || '0 * * * *';
    const marketEventsScheduler = new MarketEventsScheduler(marketEventsSchedule);
    marketEventsScheduler.start(true); // Run immediately on first start
    app.locals.marketEventsScheduler = marketEventsScheduler;

    logger.info(`Market events scheduler started with cron: ${marketEventsSchedule}`);

    // Initialize data collectors
    try {
      const collectorInit = await initializeDataCollectors();
      logger.info('Data collectors initialized', collectorInit);
    } catch (error) {
      logger.error('Failed to initialize data collectors', {
        error: error.message,
      });
      // Don't fail server startup if collectors fail to init
    }

    // Start monitoring engine
    try {
      monitoringEngine.start();
      logger.info('Monitoring engine started');
    } catch (error) {
      logger.error('Failed to start monitoring engine', {
        error: error.message,
      });
      // Don't fail server startup if monitoring engine fails
    }

    // Start push notification queue
    try {
      pushNotificationQueue.start();
      logger.info('Push notification queue started');
    } catch (error) {
      logger.error('Failed to start push notification queue', {
        error: error.message,
      });
      // Don't fail server startup if queue fails
    }

    // Graceful shutdown
    const shutdown = async () => {
      logger.info('Shutting down gracefully...');
      scheduler.stop();
      marketEventsScheduler.stop();
      monitoringEngine.stop();
      pushNotificationQueue.stop();
      server.close(() => {
        logger.info('Server closed');
        process.exit(0);
      });

      // Force shutdown after 10 seconds
      setTimeout(() => {
        logger.error('Forced shutdown after timeout');
        process.exit(1);
      }, 10000);
    };

    process.on('SIGTERM', shutdown);
    process.on('SIGINT', shutdown);

  } catch (error) {
    logger.error('Failed to start server', { error: error.message });
    process.exit(1);
  }
}

// Start the server
startServer();
