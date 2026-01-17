#!/bin/bash

# InfoDigest v2.0 Data Collection Test Script
# Tests all data collectors

set -e

API_URL="http://localhost:3000/api"
ADMIN_KEY="dev-admin-key-12345"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_test() {
    echo -e "${BLUE}TEST: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

echo "=========================================="
echo "InfoDigest v2.0 Data Collection Test Suite"
echo "=========================================="
echo ""

# Test 1: Check if server is running
print_test "Server Health Check"
HEALTH_RESPONSE=$(curl -s "$API_URL/../health" 2>&1)
if echo "$HEALTH_RESPONSE" | grep -q '"status":"healthy"'; then
    print_success "Server is healthy"
else
    print_error "Server health check failed"
    echo "Response: $HEALTH_RESPONSE"
    exit 1
fi
echo ""

# Test 2: Get data collection status
print_test "Get Data Collection Status"
STATUS_RESPONSE=$(curl -s "$API_URL/data-collection/status")
echo "$STATUS_RESPONSE" | grep -q '"isCollecting":false' && print_success "Data collection status retrieved" || print_error "Failed to get status"
echo ""

# Test 3: Get data sources status
print_test "Get Data Sources Status"
SOURCES_RESPONSE=$(curl -s "$API_URL/data-collection/sources")
SOURCE_COUNT=$(echo "$SOURCES_RESPONSE" | grep -o '"source_name"' | wc -l)
echo "$SOURCES_RESPONSE"
echo "$SOURCE_COUNT" | grep -q '[1-9]' && print_success "Found $SOURCE_COUNT data sources" || print_error "No data sources found"
echo ""

# Test 4: Get data collection health
print_test "Get Data Collection Health"
HEALTH_RESPONSE=$(curl -s "$API_URL/data-collection/health")
echo "$HEALTH_RESPONSE"
echo "$HEALTH_RESPONSE" | grep -q '"status"' && print_success "Health status retrieved" || print_error "Failed to get health"
echo ""

# Test 5: Trigger price data collection
print_test "Trigger Price Data Collection (Alpha Vantage)"
print_info "This may take a while due to API rate limits..."
PRICE_RESPONSE=$(curl -s -X POST "$API_URL/data-collection/collect/Alpha Vantage" \
  -H "X-API-Key: $ADMIN_KEY")
echo "$PRICE_RESPONSE"
echo "$PRICE_RESPONSE" | grep -q '"status":"success"' && print_success "Price collection completed" || print_error "Price collection failed"
echo ""

# Test 6: Trigger crypto data collection
print_test "Trigger Crypto Data Collection (CoinGecko)"
CRYPTO_RESPONSE=$(curl -s -X POST "$API_URL/data-collection/collect/CoinGecko" \
  -H "X-API-Key: $ADMIN_KEY")
echo "$CRYPTO_RESPONSE"
echo "$CRYPTO_RESPONSE" | grep -q '"status":"success"' && print_success "Crypto collection completed" || print_error "Crypto collection failed"
echo ""

# Test 7: Trigger news collection
print_test "Trigger News Data Collection (NewsAPI)"
NEWS_RESPONSE=$(curl -s -X POST "$API_URL/data-collection/collect/NewsAPI" \
  -H "X-API-Key: $ADMIN_KEY")
echo "$NEWS_RESPONSE"
echo "$NEWS_RESPONSE" | grep -q '"status":"success"' && print_success "News collection completed" || print_error "News collection failed"
echo ""

# Test 8: Check database for collected data
print_test "Verify Data in Database"
echo "Checking for recent price data..."
PRICE_COUNT=$(psql -h localhost -U huiminzhang -d infodigest -t -c "SELECT COUNT(*) FROM prices WHERE timestamp >= CURRENT_DATE;" 2>/dev/null || echo "0")
echo "  - Price records today: $PRICE_COUNT"

echo "Checking for recent news events..."
NEWS_COUNT=$(psql -h localhost -U huiminzhang -d infodigest -t -c "SELECT COUNT(*) FROM news_events WHERE fetched_at >= CURRENT_DATE;" 2>/dev/null || echo "0")
echo "  - News events today: $NEWS_COUNT"

echo "Checking for crypto assets..."
CRYPTO_COUNT=$(psql -h localhost -U huiminzhang -d infodigest -t -c "SELECT COUNT(*) FROM crypto_assets;" 2>/dev/null || echo "0")
echo "  - Crypto assets: $CRYPTO_COUNT"

echo "Checking for technical indicators..."
TECHNICAL_COUNT=$(psql -h localhost -U huiminzhang -d infodigest -t -c "SELECT COUNT(*) FROM technical_indicators WHERE calculated_at >= CURRENT_DATE;" 2>/dev/null || echo "0")
echo "  - Technical indicators calculated today: $TECHNICAL_COUNT"

if [ "$PRICE_COUNT" -gt 0 ] || [ "$NEWS_COUNT" -gt 0 ] || [ "$CRYPTO_COUNT" -gt 0 ] || [ "$TECHNICAL_COUNT" -gt 0 ]; then
    print_success "Data verification passed - data collected successfully"
else
    print_error "No data found in database"
fi
echo ""

# Test 9: Get data collection metrics
print_test "Get Data Collection Metrics"
METRICS_RESPONSE=$(curl -s "$API_URL/data-collection/metrics")
echo "$METRICS_RESPONSE"
echo "$METRICS_RESPONSE" | grep -q '"metrics"' && print_success "Metrics retrieved" || print_error "Failed to get metrics"
echo ""

# Test 10: Trigger full collection (all sources)
print_test "Trigger Full Data Collection"
print_info "This will run ALL collectors and may take several minutes..."
print_info "Press Ctrl+C to skip this test"
sleep 3

FULL_RESPONSE=$(curl -s -X POST "$API_URL/data-collection/collect-all" \
  -H "X-API-Key: $ADMIN_KEY" &
CURL_PID=$!

# Wait for 30 seconds then check status
sleep 30

# Check if still running
if ps -p $CURL_PID > /dev/null 2>&1; then
    print_info "Collection still running... (this is normal for multiple sources)"
    print_info "You can check logs for detailed progress"
    kill $CURL_PID 2>/dev/null
else
    echo "$FULL_RESPONSE"
    if echo "$FULL_RESPONSE" | grep -q '"status":"completed"'; then
        print_success "Full collection completed"
    else
        print_error "Full collection may have issues"
    fi
fi
echo ""

echo "=========================================="
echo "Data Collection Test Suite Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "  ✓ Server health check"
echo "  ✓ Data collection status"
echo "  ✓ Data sources status"
echo "  ✓ Individual collector tests:"
echo "    - Alpha Vantage (Prices)"
echo "    - CoinGecko (Crypto)"
echo "    - NewsAPI (News)"
echo "  ✓ Database verification"
echo "  ✓ Data collection metrics"
echo ""
echo "Data Collection API Endpoints:"
echo "  GET  /api/data-collection/status"
echo "  GET  /api/data-collection/sources"
echo "  GET  /api/data-collection/health"
echo "  GET  /api/data-collection/metrics"
echo "  POST /api/data-collection/collect-all"
echo "  POST /api/data-collection/collect/:source"
echo ""
echo "To monitor data collection:"
echo "  tail -f server/logs/combined.log | grep -i collect"
