# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

InfoDigest is an AI-powered investment monitoring and analysis platform with two major versions:

**v1.0** - Hourly push notification app delivering AI-curated content summaries (news, stock market data)
- Simple push notification pipeline: NewsAPI/AlphaVantage → LLM (DeepSeek) → PostgreSQL → APNs → iOS

**v2.0** - Comprehensive investment management platform with real-time monitoring and AI-driven insights
- Real-time strategy monitoring (every 60 seconds)
- Portfolio & watchlist management
- AI-powered market analysis
- Technical indicators and event scoring
- Dual-channel push system (instant breaking news + scheduled digests)

**Architecture**:
- **iOS Client** (Swift/SwiftUI) - MVVM pattern with 7 ViewModels and tab-based navigation
- **Node.js Server** - Modular service-oriented architecture with REST API
- **Database** - PostgreSQL with JSONB for flexible data storage
- **LLM Integration** - DeepSeek (default) or OpenAI for content generation

---

## Common Commands

### Server Development

```bash
cd server

# Install dependencies
npm install

# Initialize database (creates tables and sample data)
npm run migrate

# Development mode with auto-reload
npm run dev

# Production mode
npm start

# View logs
tail -f logs/combined.log
tail -f logs/error.log

# Database operations
psql -h localhost -U postgres -d infodigest
```

### Testing

```bash
# Run tests (when implemented)
npm test
npm run test:watch

# Manual testing - trigger digest generation
curl -X POST http://localhost:3000/api/admin/run-digest

# Test push notification
curl -X POST http://localhost:3000/api/admin/test-push \
  -H "Content-Type: application/json" \
  -d '{"title": "测试", "message": "测试消息"}'

# Test monitoring cycle
curl -X POST http://localhost:3000/api/monitoring/check-cycle \
  -H "X-API-Key: your-api-key"
```

### iOS Development

```bash
# iOS files are in InfoDigest/InfoDigest/
# Not in an Xcode project - must create project manually

# To run on simulator/device:
# 1. Create new Xcode project (iOS App, SwiftUI)
# 2. Copy Swift files to project
# 3. Configure Signing & Capabilities → Push Notifications
# 4. Set Bundle Identifier to match server config
```

---

## Architecture

### Server-Side Architecture

**Modular service-oriented architecture**:

```
src/
├── index.js                    # Express server entry point
├── config/
│   ├── database.js             # PostgreSQL connection pool
│   ├── logger.js               # Winston logging setup
│   └── init.sql                # Database schema (v1.0 only - see docs for v2.0)
├── routes/                     # API endpoints
│   ├── devices.js              # Device registration & management
│   ├── messages.js             # Message CRUD (v1.0)
│   ├── users.js                # User management (v2.0)
│   ├── portfolios.js           # Portfolio operations (v2.0)
│   ├── watchlists.js           # Watchlist management (v2.0)
│   ├── strategies.js           # Strategy CRUD (v2.0)
│   ├── temporaryFocus.js       # Temporary focus items (v2.0)
│   ├── dataCollection.js       # Data collection control (v2.0)
│   ├── monitoring.js           # Monitoring engine control (v2.0)
│   └── analysis.js             # AI analysis endpoints (v2.0)
├── services/
│   ├── monitoringEngine.js     # Real-time market monitoring (v2.0)
│   ├── llmProcessor.js         # LLM content generation
│   ├── dataFetcher.js          # News/stock data collection
│   ├── pushService.js          # APNs notification delivery
│   ├── scheduler.js            # Cron task orchestration (v1.0)
│   ├── llmAnalysisService.js   # AI analysis for strategies/events (v2.0)
│   ├── eventScoringEngine.js   # Market event importance scoring (v2.0)
│   ├── pushNotificationQueue.js # Batch notification queue (v2.0)
│   ├── strategyService.js      # Strategy business logic (v2.0)
│   ├── portfolioService.js     # Portfolio operations (v2.0)
│   ├── watchlistService.js     # Watchlist operations (v2.0)
│   └── temporaryFocusService.js # Temporary focus logic (v2.0)
├── services/collectors/        # Data collectors (v2.0)
│   ├── baseCollector.js
│   ├── priceCollector.js
│   ├── newsCollector.js
│   ├── technicalIndicatorCollector.js
│   └── [other collectors]
└── middleware/
    ├── errorHandler.js         # Error handling middleware
    ├── auth.js                 # API key authentication
    └── rateLimiter.js          # Rate limiting middleware
```

### v2.0 Data Flow

**Real-time Monitoring Pipeline** (runs every 60 seconds):

```
1. Monitoring Engine (monitoringEngine.js)
   ├─ Check active strategies
   ├─ Check temporary focus items
   ├─ Check for important market events
   └─ Cleanup expired tasks
   ↓
2. Event Scoring Engine (eventScoringEngine.js)
   - Score market events by importance (0-100)
   - Match events to user portfolios/watchlists
   ↓
3. LLM Analysis Service (llmAnalysisService.js)
   - Generate strategy explanations
   - Create focus item summaries
   - Produce event impact analysis
   ↓
4. Push Notification Queue (pushNotificationQueue.js)
   - Batch notifications for efficiency
   - Send via pushService.js to APNs
   ↓
5. iOS Client receives and displays
```

**Push Notification Channels**:
- **Breaking News**: Instant push for events with importance score ≥ 80
- **Scheduled Digests**: Daily/weekly comprehensive summaries at 9 PM

### iOS Client Architecture (v2.0)

**MVVM Pattern** with tab-based navigation:

```
InfoDigest/
├── ViewModels/                 # Business logic & state management
│   ├── DashboardViewModel.swift         # Central hub aggregation
│   ├── PortfolioViewModel.swift         # Investment holdings CRUD
│   ├── WatchlistViewModel.swift         # Watchlist management
│   ├── StrategiesViewModel.swift        # Strategy lifecycle
│   ├── TemporaryFocusViewModel.swift    # Short-term monitoring
│   ├── OpportunitiesViewModel.swift     # AI insights hub
│   └── MonitoringViewModel.swift        # System health metrics
├── Views/                      # SwiftUI views
│   ├── DashboardView.swift
│   ├── PortfolioView.swift
│   ├── WatchlistView.swift
│   ├── StrategiesView.swift
│   ├── TemporaryFocusView.swift
│   ├── OpportunitiesView.swift
│   ├── SettingsView_v1.swift
│   └── Components/            # Reusable UI components
│       ├── CircularProgressView.swift
│       ├── SimpleBarChart.swift
│       ├── SimpleLineChart.swift
│       └── AssetDistributionPie.swift
├── Models/                     # Data models
│   ├── Message.swift          # v1.0 message model
│   └── [v2.0 models in APIService.swift]
└── Services/
    ├── APIService.swift       # API communication (v1.0 + v2.0)
    └── PushNotificationManager.swift
```

**Navigation Structure**:
```
TabView
├── Tab 1: OpportunitiesView (主页 - 投资机会)
└── Tab 2: MoreFeaturesView (更多功能)
    ├── DashboardView          (仪表板)
    ├── OpportunitiesView      (投资机会分析)
    ├── PortfolioView          (投资组合)
    ├── WatchlistView          (关注列表)
    ├── StrategiesView         (策略管理)
    ├── TemporaryFocusView     (临时关注)
    └── MonitoringView         (监控状态)
```

**Key Integration Points**:
- `APIService.baseURL` must match server address
- Update for simulator vs. real device (localhost vs. IP address)
- `InfoDigestApp.swift` is app entry point
- All ViewModels marked with `@MainActor` for thread safety

---

## Configuration

### Environment Variables (.env)

**Critical variables**:

```env
# Database
DB_HOST=localhost
DB_NAME=infodigest
DB_USER=postgres
DB_PASSWORD=your_password

# LLM Provider (deepseek or openai)
LLM_PROVIDER=deepseek
LLM_MODEL=deepseek-chat
DEEPSEEK_API_KEY=sk-xxx
OPENAI_API_KEY=sk-xxx  # Optional, if using OpenAI

# Data Sources
NEWS_API_KEY=xxx
ALPHA_VANTAGE_API_KEY=xxx  # Optional

# APNs (Apple Push Notification Service)
APNS_KEY_ID=xxx
APNS_TEAM_ID=xxx
APNS_BUNDLE_ID=com.yourcompany.InfoDigest
APNS_KEY_PATH=./certs/AuthKey_XXX.p8
APNS_PRODUCTION=false  # false = sandbox, true = production

# Admin API (for monitoring endpoints)
ADMIN_API_KEY=your-secret-key

# Schedule (cron format)
CRON_SCHEDULE=0 * * * *  # Hourly (v1.0)

# Monitoring Engine (v2.0)
MONITORING_INTERVAL_MS=60000  # Check every minute
```

### LLM Provider Switching

The `llmProcessor.js` and `llmAnalysisService.js` dynamically initialize the OpenAI client based on `LLM_PROVIDER`:

- **DeepSeek** (default): Uses `https://api.deepseek.com` baseURL
- **OpenAI**: Uses default OpenAI endpoint
- Both return JSON format with specific fields

To switch providers, change `LLM_PROVIDER` in `.env` and restart server.

### iOS Configuration

**IMPORTANT**: Update `APIService.swift` for different environments:

```swift
// Development (simulator)
private let baseURL = "http://localhost:3000/api"

// Development (real device - use your machine's IP)
private let baseURL = "http://192.168.x.x:3000/api"

// Production
private let baseURL = "https://your-server.com/api"
```

**Also check**: `OpportunitiesViewModel.swift` has hardcoded URLs that need to be updated.

Bundle Identifier must match `APNS_BUNDLE_ID` in server config.

---

## Database Schema

### v1.0 Tables (defined in init.sql)

- **users** - User accounts (auto-created on device registration)
- **devices** - iOS devices with APNs tokens, linked to users
- **messages** - Generated digests with JSONB fields for images/links
- **push_logs** - Delivery tracking with status (sent/failed)
- **data_sources** - External API status and last fetch time

### v2.0 Additional Tables (see docs/DATABASE_SCHEMA_V2.md)

**Core Tables**:
- **portfolios** - User investment holdings with real-time P&L
- **watchlists** - Stocks/assets user is tracking
- **strategies** - User-defined trading/investment strategies
- **temporary_focus** - Short-term monitoring items with expiration
- **news_events** - Processed news with importance scoring
- **strategy_triggers** - History of strategy trigger events

**Analysis Tables**:
- **strategy_analyses** - AI-generated strategy analyses
- **focus_analyses** - AI-generated focus item analyses
- **event_analyses** - AI-generated market event analyses

**Support Tables**:
- **prices** - Real-time price data
- **technical_indicators** - Calculated technical indicators (RSI, MACD, etc.)

**Important**: The `init.sql` file only contains v1.0 schema. See `docs/DATABASE_SCHEMA_V2.md` for v2.0 tables. You need to manually create v2.0 tables or migrate from the documentation.

All tables use UUID primary keys. `devices.device_token` is unique and indexed.

---

## API Endpoints

### v1.0 Endpoints (Backward Compatible)

```
POST   /api/devices/register              # Register iOS device
GET    /api/messages                       # Get message history
GET    /api/messages/:id                   # Get message details
PUT    /api/messages/:id/read              # Mark as read
```

### v2.0 Endpoints

**User Management**:
```
GET    /api/users/:id                      # Get user info
PUT    /api/users/:id/preferences          # Update preferences
```

**Portfolio**:
```
GET    /api/portfolios?user_id=xxx         # Get portfolio items
POST   /api/portfolios/items               # Add holding
DELETE /api/portfolios/items/:id           # Remove holding
```

**Watchlist**:
```
GET    /api/watchlists?user_id=xxx         # Get watchlist
POST   /api/watchlists/items               # Add item
DELETE /api/watchlists/items/:id           # Remove item
```

**Strategies**:
```
GET    /api/strategies?user_id=xxx         # Get strategies
POST   /api/strategies                     # Create strategy
PUT    /api/strategies/:id/status          # Update status
DELETE /api/strategies/:id                 # Delete strategy
```

**Monitoring** (Admin only, requires API key):
```
GET    /api/monitoring/status              # Engine status
POST   /api/monitoring/start               # Start engine
POST   /api/monitoring/stop                # Stop engine
POST   /api/monitoring/check-cycle         # Manual cycle
GET    /api/monitoring/metrics             # Performance metrics
```

**Analysis**:
```
GET    /api/analysis/strategy/:strategyId  # Get strategy analysis
POST   /api/analysis/strategy/:id/generate # Generate analysis (admin)
GET    /api/analysis/focus/:focusItemId    # Get focus analysis
GET    /api/analysis/event/:eventId        # Get event analysis
```

**Data Collection**:
```
POST   /api/data-collection/start          # Start collectors
POST   /api/data-collection/stop           # Stop collectors
GET    /api/data-collection/status         # Collector status
```

---

## Development Notes

### Adding New Data Sources (v1.0)

1. Create fetcher in `dataFetcher.js` following `NewsFetcher` pattern
2. Add to `fetchAllData()` function
3. Update `data_sources` table in `init.sql`
4. Include in LLM prompt via `buildPrompt()`

### Modifying LLM Prompts

All prompts are in Chinese in `llmProcessor.js` and `llmAnalysisService.js`. System prompts define the output format (JSON with specific fields). Modify `systemPrompt` in each generation function to change content structure.

### Adding New Strategy Types (v2.0)

1. Add condition type to `strategies` table schema
2. Update `monitoringEngine.js` check logic
3. Add validation in `strategies.js` route
4. Update iOS `StrategiesViewModel` if needed

### Monitoring Engine (v2.0)

**Key Concepts**:
- Runs every 60 seconds (configurable via `MONITORING_INTERVAL_MS`)
- Checks 3 things: strategies, temporary focus items, market events
- Uses event scoring engine to evaluate importance (0-100)
- Automatically generates LLM analysis for triggers
- Batches push notifications for efficiency

**Manual Control**:
```bash
# Check status
curl http://localhost:3000/api/monitoring/status -H "X-API-Key: xxx"

# Start/Stop
curl -X POST http://localhost:3000/api/monitoring/start -H "X-API-Key: xxx"
curl -X POST http://localhost:3000/api/monitoring/stop -H "X-API-Key: xxx"

# Run single cycle
curl -X POST http://localhost:3000/api/monitoring/check-cycle -H "X-API-Key: xxx"
```

### iOS Xcode Setup

The iOS files are **not** in an Xcode project. To run:

1. Create new Xcode project (iOS App, SwiftUI)
2. Copy all Swift files from `InfoDigest/InfoDigest/` to project
3. Configure Signing & Capabilities → Push Notifications
4. Set Bundle Identifier to match server config
5. Update `APIService.swift` baseURL for your environment

See `docs/ios-development.md` for detailed steps.

---

## Debugging

### Server Issues

**Database**:
- Check connection: `npm run migrate` should run without errors
- Direct access: `psql -h localhost -U postgres -d infodigest`
- View recent data: `SELECT * FROM messages ORDER BY created_at DESC LIMIT 5;`

**LLM API**:
- Look for "Calling LLM API" log entries in `logs/combined.log`
- Check API key is set in `.env`
- Verify LLM_PROVIDER is correct (deepseek or openai)

**Monitoring Engine**:
- Status: `curl http://localhost:3000/api/monitoring/status -H "X-API-Key: xxx"`
- Logs: `tail -f logs/combined.log | grep "Monitoring"`
- Missing dependencies: Ensure all v2.0 service files exist

**APNs**:
- Verify `.p8` file path in `APNS_KEY_PATH`
- Check credentials match Apple Developer account
- Test push: `curl -X POST http://localhost:3000/api/admin/test-push`

### iOS Issues

**Push not received**:
- Check device token registered in `devices` table
- Verify `baseURL` in `APIService.swift` matches server
- Simulator cannot receive real push notifications (use test endpoints)

**API failures**:
- Verify `baseURL` matches server address
- Use real device IP for physical device testing
- Check server is running: `curl http://localhost:3000/health`

**ViewModel errors**:
- All ViewModels use `@MainActor` - ensure main thread operations
- Check `APIService` date decoding if JSON parsing fails
- Silent failures - add logging in ViewModels

### Common Failures

- **LLM API rate limits**: System auto-falls back to simple mode (v1.0)
- **Invalid device tokens**: Automatically marked inactive after 410 response
- **Missing data sources**: Logged but don't block partial digest generation
- **Monitoring engine crashes**: Check `logs/error.log` for stack traces
- **Database table missing**: v2.0 tables not in `init.sql` - create manually from docs

---

## Known Issues & TODOs

### Critical Issues

1. **Database Schema**: v2.0 tables not in `init.sql` - must be created manually from `docs/DATABASE_SCHEMA_V2.md`
2. **Hardcoded URLs**: Server IPs hardcoded in `APIService.swift` and `OpportunitiesViewModel.swift`
3. **Missing Services**: Some v2.0 services referenced but not fully implemented
4. **No Authentication**: Device token used as user ID (security risk for production)

### Configuration TODOs

- [ ] Add v2.0 tables to `init.sql` or create migration script
- [ ] Move hardcoded URLs to environment variables
- [ ] Implement proper user authentication (JWT tokens)
- [ ] Add API versioning headers

### Testing TODOs

- [ ] Unit tests for ViewModels
- [ ] Integration tests for API endpoints
- [ ] E2E tests for monitoring engine
- [ ] Manual testing checklist for v2.0 features

---

## Documentation

**Internal Documentation** (in Chinese):
- `docs/ARCHITECTURE_V2.md` - v2.0 architecture design
- `docs/DATABASE_SCHEMA_V2.md` - v2.0 database schema
- `docs/API_DESIGN.md` - API design documentation
- `docs/server-development.md` - Server development guide
- `docs/ios-development.md` - iOS development guide
- `docs/deepseek-integration.md` - LLM integration details

**Phase Completion Reports**:
- `docs/PHASE1_COMPLETION.md` - Basic server setup
- `docs/PHASE2_COMPLETION.md` - Data collection system
- `docs/PHASE3_COMPLETION.md` - Monitoring engine & LLM analysis
- `docs/PHASE4_COMPLETION.md` - API and data collection completion
- `docs/IOS_COMPLETION.md` - iOS v2.0 app development

---

## Key Files Reference

### Server
- `server/src/index.js` - Server entry point, route registration
- `server/src/services/monitoringEngine.js` - Core monitoring logic (v2.0)
- `server/src/config/init.sql` - Database schema (v1.0 only)
- `server/src/config/database.js` - PostgreSQL connection
- `server/src/services/llmProcessor.js` - LLM content generation (v1.0)
- `server/src/services/llmAnalysisService.js` - LLM analysis (v2.0)

### iOS
- `InfoDigest/InfoDigest/Services/APIService.swift` - API communication layer
- `InfoDigest/InfoDigest/ViewModels/*.swift` - Business logic
- `InfoDigest/InfoDigest/ContentView.swift` - App navigation & tabs
- `InfoDigest/InfoDigest/InfoDigestApp.swift` - App entry point

### Configuration
- `server/.env` - Environment variables
- `server/package.json` - Dependencies and scripts
