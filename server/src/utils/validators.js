/**
 * Request Validators for v2.0 API
 * Validates incoming request data
 */

/**
 * Validate email format
 */
export const isValidEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

/**
 * Validate asset type
 */
export const isValidAssetType = (type) => {
  const validTypes = ['stock', 'etf', 'index', 'crypto', 'commodity', 'forex'];
  return validTypes.includes(type);
};

/**
 * Validate symbol format (uppercase letters, numbers, some symbols)
 */
export const isValidSymbol = (symbol) => {
  // Allow: 1-10 uppercase letters, numbers, dot, hyphen
  const symbolRegex = /^[A-Z0-9]{1,10}([.\-][A-Z0-9]{1,10})*$/;
  return symbolRegex.test(symbol);
};

/**
 * Validate UUID format
 */
export const isValidUUID = (uuid) => {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
};

/**
 * Portfolio validation
 */
export const validatePortfolio = (data) => {
  const errors = [];

  if (!data.symbol) {
    errors.push('symbol is required');
  } else if (!isValidSymbol(data.symbol)) {
    errors.push('symbol format is invalid');
  }

  if (!data.assetType) {
    errors.push('assetType is required');
  } else if (!isValidAssetType(data.assetType)) {
    errors.push('assetType must be one of: stock, etf, index, crypto, commodity, forex');
  }

  if (data.shares === undefined || data.shares === null) {
    errors.push('shares is required');
  } else if (isNaN(data.shares) || data.shares <= 0) {
    errors.push('shares must be a positive number');
  }

  if (data.avgCost === undefined || data.avgCost === null) {
    errors.push('avgCost is required');
  } else if (isNaN(data.avgCost) || data.avgCost < 0) {
    errors.push('avgCost must be a non-negative number');
  }

  return {
    valid: errors.length === 0,
    errors,
  };
};

/**
 * Watchlist validation
 */
export const validateWatchlist = (data) => {
  const errors = [];

  if (!data.symbol) {
    errors.push('symbol is required');
  } else if (!isValidSymbol(data.symbol)) {
    errors.push('symbol format is invalid');
  }

  if (!data.assetType) {
    errors.push('assetType is required');
  } else if (!isValidAssetType(data.assetType)) {
    errors.push('assetType must be one of: stock, etf, index, crypto, commodity, forex');
  }

  if (data.reason) {
    const validReasons = ['potential_buy', 'competitor', 'sector_watch', 'speculative'];
    if (!validReasons.includes(data.reason)) {
      errors.push('reason must be one of: potential_buy, competitor, sector_watch, speculative');
    }
  }

  if (data.priority !== undefined) {
    if (isNaN(data.priority) || data.priority < 1 || data.priority > 10) {
      errors.push('priority must be between 1 and 10');
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  };
};

/**
 * Strategy validation
 */
export const validateStrategy = (data) => {
  const errors = [];

  if (!data.name) {
    errors.push('name is required');
  }

  if (!data.symbol) {
    errors.push('symbol is required');
  } else if (!isValidSymbol(data.symbol)) {
    errors.push('symbol format is invalid');
  }

  if (!data.conditionType) {
    errors.push('conditionType is required');
  } else {
    const validConditionTypes = ['price', 'technical', 'news', 'time', 'portfolio_change'];
    if (!validConditionTypes.includes(data.conditionType)) {
      errors.push('conditionType must be one of: price, technical, news, time, portfolio_change');
    }
  }

  if (!data.conditions || typeof data.conditions !== 'object') {
    errors.push('conditions is required and must be an object');
  }

  if (!data.action || typeof data.action !== 'object') {
    errors.push('action is required and must be an object');
  } else {
    if (!data.action.type) {
      errors.push('action.type is required');
    } else {
      const validActionTypes = ['buy', 'sell', 'hold', 'adjust', 'alert'];
      if (!validActionTypes.includes(data.action.type)) {
        errors.push('action.type must be one of: buy, sell, hold, adjust, alert');
      }
    }

    if (!data.action.reason) {
      errors.push('action.reason is required');
    }
  }

  if (data.priority !== undefined) {
    if (isNaN(data.priority) || data.priority < 1 || data.priority > 10) {
      errors.push('priority must be between 1 and 10');
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  };
};

/**
 * Temporary focus validation
 */
export const validateTemporaryFocus = (data) => {
  const errors = [];

  if (!data.title) {
    errors.push('title is required');
  }

  if (!data.targets || !Array.isArray(data.targets) || data.targets.length === 0) {
    errors.push('targets is required and must be a non-empty array');
  }

  if (!data.expiresAt) {
    errors.push('expiresAt is required');
  } else {
    const expiresAt = new Date(data.expiresAt);
    const now = new Date();
    if (expiresAt <= now) {
      errors.push('expiresAt must be in the future');
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  };
};

/**
 * User preferences validation
 */
export const validatePreferences = (preferences) => {
  const errors = [];

  if (!preferences || typeof preferences !== 'object') {
    return { valid: true, errors: [] }; // preferences are optional
  }

  if (preferences.analysisLength) {
    const validLengths = ['full', 'summary'];
    if (!validLengths.includes(preferences.analysisLength)) {
      errors.push('analysisLength must be either "full" or "summary"');
    }
  }

  if (preferences.pushFrequency) {
    const validFrequencies = ['minimal', 'normal', 'all'];
    if (!validFrequencies.includes(preferences.pushFrequency)) {
      errors.push('pushFrequency must be one of: minimal, normal, all');
    }
  }

  if (preferences.riskProfile) {
    const validProfiles = ['conservative', 'neutral', 'aggressive'];
    if (!validProfiles.includes(preferences.riskProfile)) {
      errors.push('riskProfile must be one of: conservative, neutral, aggressive');
    }
  }

  if (preferences.quietHours) {
    if (preferences.quietHours.enabled) {
      // Validate time format HH:MM
      const timeRegex = /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/;
      if (preferences.quietHours.start && !timeRegex.test(preferences.quietHours.start)) {
        errors.push('quietHours.start must be in HH:MM format');
      }
      if (preferences.quietHours.end && !timeRegex.test(preferences.quietHours.end)) {
        errors.push('quietHours.end must be in HH:MM format');
      }
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  };
};

/**
 * Validation error class
 */
export class ValidationError extends Error {
  constructor(errors) {
    const message = Array.isArray(errors) ? errors.join(', ') : errors;
    super(message);
    this.statusCode = 400;
    this.name = 'ValidationError';
  }
}
