/**
 * Data Collection Initialization
 * Registers all data collectors with the coordinator
 */

import dataCollector from './dataCollector.js';
import PriceCollector from './collectors/priceCollector.js';
import CryptoCollector from './collectors/cryptoCollector.js';
import NewsCollector from './collectors/newsCollector.js';
import TechnicalIndicatorCollector from './collectors/technicalIndicatorCollector.js';
import SectorCollector from './collectors/sectorCollector.js';
import MacroCollector from './collectors/macroCollector.js';
import IndexCollector from './collectors/indexCollector.js';
import CommoditiesCollector from './collectors/commoditiesCollector.js';
import logger from '../config/logger.js';

/**
 * Initialize all data collectors
 */
export async function initializeDataCollectors() {
  try {
    logger.info('Initializing data collectors');

    // Price Data Collector
    const priceCollector = new PriceCollector();
    dataCollector.registerCollector('Alpha Vantage', priceCollector);

    // Crypto Data Collector
    const cryptoCollector = new CryptoCollector();
    dataCollector.registerCollector('CoinGecko', cryptoCollector);

    // News Collector
    const newsCollector = new NewsCollector();
    dataCollector.registerCollector('NewsAPI', newsCollector);

    // Technical Indicator Calculator
    const technicalCollector = new TechnicalIndicatorCollector();
    dataCollector.registerCollector('TechnicalIndicators', technicalCollector);

    // Sector Performance Aggregator
    const sectorCollector = new SectorCollector();
    dataCollector.registerCollector('SectorAggregator', sectorCollector);

    // Macro Economic Data Collector
    const macroCollector = new MacroCollector();
    dataCollector.registerCollector('FRED', macroCollector);

    // Index Collector (A-shares, US ETFs, Commodities, Forex)
    const indexCollector = new IndexCollector();
    dataCollector.registerCollector('Index', indexCollector);

    // Commodities Collector (Gold, Oil)
    const commoditiesCollector = new CommoditiesCollector();
    dataCollector.registerCollector('Commodities', commoditiesCollector);

    logger.info('All data collectors registered successfully', {
      count: 8,
      collectors: Array.from(dataCollector.collectors.keys()),
    });

    return {
      success: true,
      collectors: Array.from(dataCollector.collectors.keys()),
    };
  } catch (error) {
    logger.error('Failed to initialize data collectors', {
      error: error.message,
    });
    throw error;
  }
}

/**
 * Start periodic data collection
 * @param {string} schedule - Cron schedule (e.g., '0 * * * *' for hourly)
 */
export async function startPeriodicCollection(schedule = '0 * * * *') {
  try {
    logger.info('Starting periodic data collection', { schedule });

    // Import cron
    const cron = require('node-cron');

    // Schedule data collection
    cron.schedule(schedule, async () => {
      try {
        logger.info('Running scheduled data collection');
        await dataCollector.collectAll();
      } catch (error) {
        logger.error('Scheduled data collection failed', {
          error: error.message,
        });
      }
    });

    logger.info('Periodic data collection started', { schedule });
  } catch (error) {
    logger.error('Failed to start periodic collection', {
      error: error.message,
    });
    throw error;
  }
}

export default {
  initializeDataCollectors,
  startPeriodicCollection,
};
