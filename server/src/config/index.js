import dotenv from 'dotenv';
dotenv.config();

export default {
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',

  database: {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    name: process.env.DB_NAME || 'infodigest',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'password',
  },

  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD || undefined,
  },

  apiKeys: {
    news: process.env.NEWS_API_KEY,
    stock: process.env.STOCK_API_KEY,
    deepseek: process.env.DEEPSEEK_API_KEY,
    openai: process.env.OPENAI_API_KEY,
    anthropic: process.env.ANTHROPIC_API_KEY,
  },

  llm: {
    provider: process.env.LLM_PROVIDER || 'deepseek', // 'deepseek', 'openai', 'anthropic'
    model: process.env.LLM_MODEL || 'deepseek-chat',
    deepseekBaseUrl: 'https://api.deepseek.com',
  },

  apns: {
    keyId: process.env.APNS_KEY_ID,
    teamId: process.env.APNS_TEAM_ID,
    bundleId: process.env.APNS_BUNDLE_ID,
    keyPath: process.env.APNS_KEY_PATH,
    production: process.env.APNS_PRODUCTION === 'true',
  },

  jwt: {
    secret: process.env.JWT_SECRET || 'change-this-secret',
  },

  cron: {
    schedule: process.env.CRON_SCHEDULE || '0 * * * *',
  },

  marketEvents: {
    enabled: process.env.MARKET_EVENTS_ENABLED !== 'false',
    schedule: process.env.MARKET_EVENTS_SCHEDULE || '0 * * * *',
    minScore: parseInt(process.env.MARKET_EVENTS_MIN_SCORE) || 60,
    hours: parseInt(process.env.MARKET_EVENTS_HOURS) || 1,
  },
};
