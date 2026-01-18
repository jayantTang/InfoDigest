/**
 * Event Importance Scoring Engine for v2.0
 * Calculates importance scores (0-100) for market events
 */

import logger from '../config/logger.js';
import { pool } from '../config/database.js';

class EventScoringEngine {
  constructor() {
    // Scoring weights
    this.weights = {
      priceMovement: 0.3, // 30% weight for price movement
      volume: 0.2, // 20% weight for volume anomaly
      technical: 0.2, // 20% weight for technical signals
      news: 0.2, // 20% weight for news importance
      userRelevance: 0.1, // 10% weight for user relevance
    };
  }

  /**
   * Calculate overall importance score for a market event
   * @param {Object} eventData - Event data
   * @param {string} eventData.symbol - Stock/crypto symbol
   * @param {Object} eventData.marketData - Current market data
   * @param {Array} eventData.news - Related news articles
   * @param {Object} eventData.userContext - User's portfolio/watchlist context
   * @returns {Object} Score breakdown and total score
   */
  async calculateImportanceScore(eventData) {
    try {
      const { symbol, marketData, news, userContext } = eventData;

      // Calculate individual scores
      const priceScore = await this.calculatePriceMovementScore(marketData);
      const volumeScore = await this.calculateVolumeScore(marketData);
      const technicalScore = await this.calculateTechnicalScore(marketData);
      const newsScore = this.calculateNewsScore(news);
      const relevanceScore = this.calculateUserRelevanceScore(userContext);

      // Calculate weighted total
      const totalScore =
        priceScore * this.weights.priceMovement +
        volumeScore * this.weights.volume +
        technicalScore * this.weights.technical +
        newsScore * this.weights.news +
        relevanceScore * this.weights.userRelevance;

      const scoreBreakdown = {
        price: {
          score: priceScore,
          weight: this.weights.priceMovement,
          weighted: priceScore * this.weights.priceMovement,
          details: this.getPriceMovementDetails(marketData),
        },
        volume: {
          score: volumeScore,
          weight: this.weights.volume,
          weighted: volumeScore * this.weights.volume,
          details: this.getVolumeDetails(marketData),
        },
        technical: {
          score: technicalScore,
          weight: this.weights.technical,
          weighted: technicalScore * this.weights.technical,
          details: this.getTechnicalDetails(marketData),
        },
        news: {
          score: newsScore,
          weight: this.weights.news,
          weighted: newsScore * this.weights.news,
          details: this.getNewsDetails(news),
        },
        userRelevance: {
          score: relevanceScore,
          weight: this.weights.userRelevance,
          weighted: relevanceScore * this.weights.userRelevance,
          details: this.getRelevanceDetails(userContext),
        },
      };

      // Round to 2 decimal places
      const finalScore = Math.round(totalScore * 100) / 100;

      logger.debug('Importance score calculated', {
        symbol,
        totalScore: finalScore,
        breakdown: scoreBreakdown,
      });

      return {
        totalScore: Math.min(100, Math.max(0, finalScore)),
        breakdown: scoreBreakdown,
        level: this.getScoreLevel(finalScore),
      };
    } catch (error) {
      logger.error('Failed to calculate importance score', {
        error: error.message,
        eventData,
      });
      return {
        totalScore: 50, // Default score on error
        breakdown: {},
        level: 'medium',
      };
    }
  }

  /**
   * Calculate price movement score (0-100)
   */
  async calculatePriceMovementScore(marketData) {
    if (!marketData || !marketData.price) {
      return 0;
    }

    const price = marketData.price;
    let score = 0;

    // Price change percentage
    if (price.change_percent) {
      const changeAbs = Math.abs(price.change_percent);
      // 1% change = 20 points, 5%+ change = 100 points
      score = Math.min(100, changeAbs * 20);
    }

    // Intraday movement (high - low)
    if (price.high_price && price.low_price && price.close_price) {
      const intradayRange = ((price.high_price - price.low_price) / price.close_price) * 100;
      // Add bonus for high volatility
      score += Math.min(20, intradayRange * 2);
    }

    return Math.min(100, score);
  }

  /**
   * Calculate volume anomaly score (0-100)
   */
  async calculateVolumeScore(marketData) {
    if (!marketData || !marketData.price || !marketData.technical) {
      return 0;
    }

    const price = marketData.price;
    const technical = marketData.technical;

    let score = 0;

    // Compare current volume to average volume
    if (price.volume && technical.volume_avg_20) {
      const volumeRatio = price.volume / technical.volume_avg_20;

      if (volumeRatio >= 3) {
        // 3x+ average volume = 100 points
        score = 100;
      } else if (volumeRatio >= 2) {
        // 2x average volume = 80 points
        score = 80;
      } else if (volumeRatio >= 1.5) {
        // 1.5x average volume = 60 points
        score = 60;
      } else if (volumeRatio >= 1.2) {
        // 1.2x average volume = 40 points
        score = 40;
      } else {
        // Normal volume
        score = 10;
      }
    }

    return score;
  }

  /**
   * Calculate technical signal score (0-100)
   */
  async calculateTechnicalScore(marketData) {
    if (!marketData || !marketData.technical) {
      return 0;
    }

    const tech = marketData.technical;
    let score = 0;

    // RSI extreme levels
    if (tech.rsi) {
      if (tech.rsi <= 30) {
        // Oversold - bullish signal
        score += 30;
      } else if (tech.rsi >= 70) {
        // Overbought - bearish signal
        score += 30;
      } else if (tech.rsi <= 40 || tech.rsi >= 60) {
        // Approaching extremes
        score += 15;
      }
    }

    // MACD crossover
    if (tech.macd_histogram) {
      const histogramAbs = Math.abs(tech.macd_histogram);
      // Strong momentum
      score += Math.min(30, histogramAbs * 100);
    }

    // Bollinger Band breakout
    if (tech.bollinger_upper && tech.bollinger_lower && marketData.price) {
      const price = marketData.price.close_price;
      const upper = tech.bollinger_upper;
      const lower = tech.bollinger_lower;

      if (price >= upper * 0.99) {
        // Touching/above upper band
        score += 30;
      } else if (price <= lower * 1.01) {
        // Touching/below lower band
        score += 30;
      }
    }

    return Math.min(100, score);
  }

  /**
   * Calculate news importance score (0-100)
   */
  calculateNewsScore(news) {
    if (!news || news.length === 0) {
      return 0;
    }

    // Use the highest importance score from recent news
    const maxImportance = Math.max(...news.map((n) => n.importance_score || 0));

    // Adjust for recency and quantity
    let score = maxImportance;

    // Bonus for multiple important news
    const importantNewsCount = news.filter((n) => n.importance_score >= 70).length;
    if (importantNewsCount > 1) {
      score += Math.min(20, importantNewsCount * 5);
    }

    return Math.min(100, score);
  }

  /**
   * Calculate user relevance score (0-100)
   */
  calculateUserRelevanceScore(userContext) {
    if (!userContext) {
      return 0;
    }

    let score = 0;

    // In portfolio = higher relevance
    if (userContext.inPortfolio) {
      score += 60;
    }

    // In watchlist = medium relevance
    if (userContext.inWatchlist) {
      score += 30;
    }

    // Temporary focus = very high relevance
    if (userContext.inTemporaryFocus) {
      score += 100;
    }

    // Large position size = higher relevance
    if (userContext.positionSize) {
      if (userContext.positionSize > 0.1) {
        // >10% of portfolio
        score += 20;
      } else if (userContext.positionSize > 0.05) {
        // >5% of portfolio
        score += 10;
      }
    }

    return Math.min(100, score);
  }

  /**
   * Get price movement details for logging
   */
  getPriceMovementDetails(marketData) {
    if (!marketData || !marketData.price) {
      return {};
    }

    const price = marketData.price;
    return {
      changePercent: price.change_percent,
      openPrice: price.open_price,
      closePrice: price.close_price,
      highPrice: price.high_price,
      lowPrice: price.low_price,
    };
  }

  /**
   * Get volume details for logging
   */
  getVolumeDetails(marketData) {
    if (!marketData || !marketData.price || !marketData.technical) {
      return {};
    }

    return {
      currentVolume: marketData.price.volume,
      avgVolume20: marketData.technical.volume_avg_20,
      ratio: marketData.technical.volume_avg_20
        ? (marketData.price.volume / marketData.technical.volume_avg_20).toFixed(2)
        : null,
    };
  }

  /**
   * Get technical details for logging
   */
  getTechnicalDetails(marketData) {
    if (!marketData || !marketData.technical) {
      return {};
    }

    return {
      rsi: marketData.technical.rsi,
      macdHistogram: marketData.technical.macd_histogram,
      bollingerUpper: marketData.technical.bollinger_upper,
      bollingerLower: marketData.technical.bollinger_lower,
    };
  }

  /**
   * Get news details for logging
   */
  getNewsDetails(news) {
    if (!news || news.length === 0) {
      return { count: 0 };
    }

    return {
      count: news.length,
      maxImportance: Math.max(...news.map((n) => n.importance_score || 0)),
      categories: [...new Set(news.map((n) => n.category))],
    };
  }

  /**
   * Get relevance details for logging
   */
  getRelevanceDetails(userContext) {
    if (!userContext) {
      return {};
    }

    return {
      inPortfolio: userContext.inPortfolio,
      inWatchlist: userContext.inWatchlist,
      inTemporaryFocus: userContext.inTemporaryFocus,
      positionSize: userContext.positionSize,
    };
  }

  /**
   * Get score level category
   */
  getScoreLevel(score) {
    if (score >= 80) {
      return 'critical';
    } else if (score >= 60) {
      return 'high';
    } else if (score >= 40) {
      return 'medium';
    } else if (score >= 20) {
      return 'low';
    } else {
      return 'minimal';
    }
  }

  /**
   * Batch calculate scores for multiple events
   */
  async batchCalculateScores(events) {
    const scores = await Promise.all(
      events.map(async (event) => {
        const score = await this.calculateImportanceScore(event);
        return {
          symbol: event.symbol,
          score,
        };
      })
    );

    return scores;
  }

  /**
   * Get top scoring events
   */
  getTopEvents(scoredEvents, limit = 10) {
    return scoredEvents
      .sort((a, b) => b.score.totalScore - a.score.totalScore)
      .slice(0, limit);
  }
}

// Singleton instance
const eventScoringEngine = new EventScoringEngine();

export default eventScoringEngine;
