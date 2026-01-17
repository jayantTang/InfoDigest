# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

InfoDigest is an iOS push notification app that delivers AI-curated content summaries (news, stock market data, etc.) on an hourly basis. The system consists of:

1. **iOS Client** (Swift/SwiftUI) - Receives and displays push notifications with rich content
2. **Node.js Server** - Fetches data, processes with LLM, and sends APNs pushes
3. **Data Pipeline**: NewsAPI/AlphaVantage → LLM (DeepSeek) → PostgreSQL → APNs → iOS

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
```

### Testing

```bash
# Run tests (when implemented)
npm test

# Manual testing - trigger digest generation
curl -X POST http://localhost:3000/api/admin/run-digest

# Test push notification
curl -X POST http://localhost:3000/api/admin/test-push \
  -H "Content-Type: application/json" \
  -d '{"title": "测试", "message": "测试消息"}'
```

### Database

```bash
# Initialize/reset database schema
npm run migrate

# Check PostgreSQL connection
psql -h localhost -U postgres -d infodigest

# View recent messages
psql -h localhost -U postgres -d infodigest -c "SELECT * FROM messages ORDER BY created_at DESC LIMIT 5;"
```

## Architecture

### Server-Side Architecture

The server follows a modular service-oriented architecture:

```
src/
├── index.js              # Express server entry point
├── config/
│   ├── database.js       # PostgreSQL connection pool
│   ├── logger.js         # Winston logging setup
│   └── init.sql          # Database schema
├── routes/
│   ├── devices.js        # Device registration & management
│   └── messages.js       # Message CRUD operations
├── services/
│   ├── dataFetcher.js    # News/Stock data collection
│   ├── llmProcessor.js   # LLM content generation
│   ├── pushService.js    # APNs notification delivery
│   └── scheduler.js      # Cron task orchestration
└── middleware/
    └── errorHandler.js   # Error handling middleware
```

### Data Flow Pipeline

**Hourly Scheduled Task** (`scheduler.js`):

1. **Data Fetching** (`dataFetcher.js`)
   - Fetches from NewsAPI (tech news)
   - Fetches from Alpha Vantage (stock quotes)
   - Updates `data_sources` table with status

2. **LLM Processing** (`llmProcessor.js`)
   - Configurable LLM provider: DeepSeek (default) or OpenAI
   - Switch controlled by `LLM_PROVIDER` env var
   - Generates Markdown digest with Chinese-optimized prompts
   - Falls back to simple text generation if API fails

3. **Database Persistence**
   - Saves message to `messages` table
   - Stores rich content, images, links as JSONB

4. **Push Notification** (`pushService.js`)
   - Queries all active iOS devices from `devices` table
   - Sends via APNs using authentication key (.p8 file)
   - Logs delivery status in `push_logs` table
   - Auto-deactivates invalid device tokens

### iOS Client Architecture

SwiftUI MVVM pattern:

- **Models/** - `Message.swift` (data models with sample data for preview)
- **Views/** - SwiftUI views (MessageList, MessageDetail, Settings)
- **ViewModels/** - `MessageListViewModel.swift` (state management)
- **Services/** - `APIService.swift`, `PushNotificationManager.swift`

Key integration points:
- `APIService.baseURL` must match server address
- `AppDelegate.swift` handles APNs callbacks
- Device token sent to `/api/devices/register` on launch

## Configuration

### Environment Variables (.env)

Critical variables:

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

# Data Sources
NEWS_API_KEY=xxx
STOCK_API_KEY=xxx  # Optional

# APNs
APNS_KEY_ID=xxx
APNS_TEAM_ID=xxx
APNS_BUNDLE_ID=com.yourcompany.InfoDigest
APNS_KEY_PATH=./certs/AuthKey_XXX.p8
APNS_PRODUCTION=false

# Schedule (cron format)
CRON_SCHEDULE=0 * * * *  # Hourly
```

### LLM Provider Switching

The `llmProcessor.js` dynamically initializes the OpenAI client based on `LLM_PROVIDER`:

- **DeepSeek** (default): Uses `https://api.deepseek.com` baseURL
- **OpenAI**: Uses default OpenAI endpoint
- Both return JSON format with `title`, `summary`, `content`, `links`

To switch providers, change `LLM_PROVIDER` in `.env` and restart server.

### iOS Configuration

Update `APIService.swift` for different environments:

```swift
// Development (simulator)
private let baseURL = "http://localhost:3000/api"

// Development (real device)
private let baseURL = "http://192.168.x.x:3000/api"

// Production
private let baseURL = "https://your-server.com/api"
```

Bundle Identifier must match `APNS_BUNDLE_ID` in server config.

## Database Schema

Key tables:

- **users** - User accounts (auto-created on device registration)
- **devices** - iOS devices with APNs tokens, linked to users
- **messages** - Generated digests with JSONB fields for images/links
- **push_logs** - Delivery tracking with status (sent/failed)
- **data_sources** - External API status and last fetch time

All tables use UUID primary keys. `devices.device_token` is unique and indexed.

## APNs Implementation

Uses token-based authentication (APNs Auth Key .p8 file):

1. Key file stored in `server/certs/`
2. Provider initialized in `pushService.js` with key/team ID
3. Batch sends to all active devices (20 concurrent)
4. Handles 410 errors by marking devices inactive
5. Logs all attempts to `push_logs` table

## Development Notes

### Adding New Data Sources

1. Create fetcher in `dataFetcher.js` following `NewsFetcher` pattern
2. Add to `fetchAllData()` function
3. Update `data_sources` table in `init.sql`
4. Include in LLM prompt via `buildPrompt()`

### Modifying LLM Prompts

All prompts are in Chinese in `llmProcessor.js`. System prompts define the output format (JSON with specific fields). Modify `systemPrompt` in each generation function to change content structure.

### iOS Xcode Setup

The iOS files are not in an Xcode project. To run:

1. Create new Xcode project (iOS App, SwiftUI)
2. Copy Swift files from `InfoDigest/InfoDigest/` to project
3. Configure Signing & Capabilities → Push Notifications
4. Set Bundle Identifier to match server config

See `InfoDigest/SETUP_GUIDE.md` for detailed steps.

## Debugging

### Server Issues

- Check logs: `tail -f server/logs/combined.log`
- Database connection: `npm run migrate` should run without errors
- LLM API: Look for "Calling LLM API" log entries
- APNs: Verify `.p8` file path and credentials match Apple Developer

### iOS Issues

- Push not received: Check device token registered in `devices` table
- API failures: Verify `baseURL` matches server address
- Simulator: Cannot receive real push notifications, use test endpoints

### Common Failures

- **LLM API rate limits**: System auto-falls back to simple mode
- **Invalid device tokens**: Automatically marked inactive after 410 response
- **Missing data sources**: Logged but don't block partial digest generation
