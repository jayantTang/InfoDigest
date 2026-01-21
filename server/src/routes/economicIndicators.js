/**
 * Economic Indicators Routes
 * Provides unified endpoint for all economic indicators
 * Includes A-stock indices, US ETFs, commodities, forex, and macro data
 */

import express from 'express';
import { pool } from '../config/database.js';
import { responseHelpers } from '../middleware/responseFormatter.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import logger from '../config/logger.js';

const router = express.Router();

// Apply response helpers middleware
router.use(responseHelpers);

// In-memory cache (10-minute TTL)
let cache = {
  data: null,
  timestamp: null,
  ttl: 10 * 60 * 1000, // 10 minutes
};

/**
 * GET /api/economic-indicators
 * Get all economic indicators with caching
 */
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const now = Date.now();

    // Check cache
    if (cache.data && cache.timestamp && (now - cache.timestamp < cache.ttl)) {
      logger.debug('Returning cached economic indicators');
      return res.success({
        ...cache.data,
        cached: true,
      });
    }

    logger.info('Fetching fresh economic indicators data');

    // Fetch all data in parallel
    const [aStockIndices, usEtfIndices, commodities, forex, macroData] = await Promise.all([
      fetchAStockIndices(),
      fetchUsEtfIndices(),
      fetchCommodities(),
      fetchForex(),
      fetchMacroData(),
    ]);

    const responseData = {
      aStockIndices,
      usEtfIndices,
      commodities,
      forex,
      macroData,
    };

    // Update cache
    cache.data = responseData;
    cache.timestamp = now;

    logger.info('Economic indicators fetched successfully', {
      aStockCount: aStockIndices.length,
      usEtfCount: usEtfIndices.length,
      commoditiesCount: commodities.length,
      forexCount: forex.length,
      macroDataCount: Object.keys(macroData).length,
    });

    return res.success({
      ...responseData,
      cached: false,
    });
  })
);

/**
 * Fetch A-stock indices from prices table
 */
async function fetchAStockIndices() {
  const symbols = ['000001.SS', '000300.SS', '399006.SZ'];
  return fetchIndexData(symbols, 'CN');
}

/**
 * Fetch US ETF indices from prices table
 */
async function fetchUsEtfIndices() {
  const symbols = ['SPY', 'QQQ', 'DIA'];
  return fetchIndexData(symbols, 'US');
}

/**
 * Fetch commodities from prices table
 */
async function fetchCommodities() {
  const symbols = ['GC=F', 'CL=F'];
  return fetchIndexData(symbols, 'COMMODITY');
}

/**
 * Fetch forex data from prices table
 */
async function fetchForex() {
  const symbols = ['DX-Y.NYB'];
  return fetchIndexData(symbols, 'FOREX');
}

/**
 * Generic function to fetch index data for given symbols
 * @param {Array<string>} symbols - List of symbols to fetch
 * @param {string} category - Category for grouping
 * @returns {Array<Object>} Array of index data with metadata
 */
async function fetchIndexData(symbols, category) {
  const query = `
    SELECT DISTINCT ON (symbol)
      symbol,
      close_price as price,
      timestamp,
      EXTRACT(EPOCH FROM ($2 - timestamp)) / 60 as minutes_ago
    FROM prices
    WHERE symbol = ANY($1)
      AND timestamp >= CURRENT_DATE - INTERVAL '7 days'
    ORDER BY symbol, timestamp DESC
  `;

  const result = await pool.query(query, [symbols, new Date()]);

  // Map symbol to display names
  const displayNameMap = {
    '000001.SS': '上证指数',
    '000300.SS': '沪深300',
    '399006.SZ': '创业板指',
    'SPY': '标普500',
    'QQQ': '纳斯达克100',
    'DIA': '道琼斯',
    'GC=F': '黄金',
    'CL=F': '石油',
    'DX-Y.NYB': '美元指数',
  };

  return result.rows.map(row => ({
    symbol: row.symbol,
    name: displayNameMap[row.symbol] || row.symbol,
    price: parseFloat(row.price),
    timestamp: row.timestamp,
    isStale: parseInt(row.minutes_ago) > 15, // Consider stale if > 15 minutes
  }));
}

/**
 * Fetch macro economic data from macro_data table
 * @returns {Object} Map of indicator code to data
 */
async function fetchMacroData() {
  const query = `
    SELECT DISTINCT ON (indicator_code)
      indicator_code,
      indicator_name as name,
      value,
      unit,
      period,
      released_at as timestamp
    FROM macro_data
    WHERE released_at >= CURRENT_DATE - INTERVAL '30 days'
    ORDER BY indicator_code, released_at DESC
  `;

  const result = await pool.query(query);

  // Convert array to object keyed by indicator_code
  const macroMap = {};
  for (const row of result.rows) {
    const periodFormatted = row.period.toISOString().split('T')[0];
    macroMap[row.indicator_code] = {
      name: row.name,
      value: parseFloat(row.value),
      unit: row.unit,
      period: periodFormatted,
      frequency: 'Monthly', // Default frequency since column doesn't exist
      timestamp: row.timestamp,
    };
  }

  return macroMap;
}

/**
 * Clear cache (for admin use)
 * POST /api/economic-indicators/clear-cache
 */
router.post(
  '/clear-cache',
  asyncHandler(async (req, res) => {
    cache.data = null;
    cache.timestamp = null;
    logger.info('Economic indicators cache cleared');

    return res.success({ message: 'Cache cleared successfully' });
  })
);

export default router;
