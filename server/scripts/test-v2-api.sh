#!/bin/bash

# InfoDigest v2.0 API Test Script
# Tests all v2.0 API endpoints

set -e

API_URL="http://localhost:3000/api"
DEVICE_TOKEN="test-device-token-$(date +%s)"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
print_test() {
    echo -e "${YELLOW}TEST: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Store data for subsequent tests
USER_ID=""
PORTFOLIO_ID=""
WATCHLIST_ID=""
STRATEGY_ID=""
TEMP_FOCUS_ID=""

echo "=========================================="
echo "InfoDigest v2.0 API Test Suite"
echo "=========================================="
echo ""

# Test 1: Health Check
print_test "Health Check"
HEALTH_RESPONSE=$(curl -s "$API_URL/../health")
echo "$HEALTH_RESPONSE" | grep -q '"status":"healthy"' && print_success "Health check passed" || print_error "Health check failed"
echo ""

# Test 2: User Registration
print_test "User Registration"
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/users/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"deviceToken\": \"$DEVICE_TOKEN\",
    \"platform\": \"ios\",
    \"initialConfig\": {
      \"preferences\": {
        \"analysisLength\": \"full\",
        \"pushFrequency\": \"normal\"
      }
    }
  }")

echo "$REGISTER_RESPONSE"
USER_ID=$(echo "$REGISTER_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$USER_ID" ]; then
    print_success "User registered successfully (ID: $USER_ID)"
else
    print_error "User registration failed"
fi
echo ""

# Test 3: Get User Profile
print_test "Get User Profile"
PROFILE_RESPONSE=$(curl -s -X GET "$API_URL/users/profile" \
  -H "X-Device-Token: $DEVICE_TOKEN")

echo "$PROFILE_RESPONSE"
echo "$PROFILE_RESPONSE" | grep -q '"success":true' && print_success "Get profile successful" || print_error "Get profile failed"
echo ""

# Test 4: Update User Preferences
print_test "Update User Preferences"
PREFS_RESPONSE=$(curl -s -X PUT "$API_URL/users/preferences" \
  -H "Content-Type: application/json" \
  -H "X-Device-Token: $DEVICE_TOKEN" \
  -d "{
    \"analysisLength\": \"summary\",
    \"pushFrequency\": \"minimal\",
    \"riskProfile\": \"aggressive\"
  }")

echo "$PREFS_RESPONSE"
echo "$PREFS_RESPONSE" | grep -q '"success":true' && print_success "Preferences updated" || print_error "Preferences update failed"
echo ""

# Test 5: Get User Stats
print_test "Get User Stats"
STATS_RESPONSE=$(curl -s -X GET "$API_URL/users/stats" \
  -H "X-Device-Token: $DEVICE_TOKEN")

echo "$STATS_RESPONSE"
echo "$STATS_RESPONSE" | grep -q '"success":true' && print_success "Get stats successful" || print_error "Get stats failed"
echo ""

# Test 6: Create Portfolio
print_test "Create Portfolio Position"
PORTFOLIO_RESPONSE=$(curl -s -X POST "$API_URL/portfolios" \
  -H "Content-Type: application/json" \
  -H "X-Device-Token: $DEVICE_TOKEN" \
  -d "{
    \"symbol\": \"NVDA\",
    \"assetType\": \"stock\",
    \"exchange\": \"NASDAQ\",
    \"shares\": 100,
    \"avgCost\": 880.00,
    \"alerts\": {
      \"priceAbove\": 900,
      \"priceBelow\": 800
    }
  }")

echo "$PORTFOLIO_RESPONSE"
PORTFOLIO_ID=$(echo "$PORTFOLIO_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$PORTFOLIO_ID" ]; then
    print_success "Portfolio created (ID: $PORTFOLIO_ID)"
else
    print_error "Portfolio creation failed"
fi
echo ""

# Test 7: Get All Portfolios
print_test "Get All Portfolios"
GET_PORTFOLIOS_RESPONSE=$(curl -s -X GET "$API_URL/portfolios" \
  -H "X-Device-Token: $DEVICE_TOKEN")

echo "$GET_PORTFOLIOS_RESPONSE"
echo "$GET_PORTFOLIOS_RESPONSE" | grep -q '"success":true' && print_success "Get portfolios successful" || print_error "Get portfolios failed"
echo ""

# Test 8: Get Portfolio Summary
print_test "Get Portfolio Summary"
SUMMARY_RESPONSE=$(curl -s -X GET "$API_URL/portfolios/summary" \
  -H "X-Device-Token: $DEVICE_TOKEN")

echo "$SUMMARY_RESPONSE"
echo "$SUMMARY_RESPONSE" | grep -q '"success":true' && print_success "Get summary successful" || print_error "Get summary failed"
echo ""

# Test 9: Update Portfolio
if [ -n "$PORTFOLIO_ID" ]; then
    print_test "Update Portfolio Position"
    UPDATE_PORTFOLIO_RESPONSE=$(curl -s -X PUT "$API_URL/portfolios/$PORTFOLIO_ID" \
      -H "Content-Type: application/json" \
      -H "X-Device-Token: $DEVICE_TOKEN" \
      -d "{
        \"shares\": 150,
        \"avgCost\": 870.00
      }")

    echo "$UPDATE_PORTFOLIO_RESPONSE"
    echo "$UPDATE_PORTFOLIO_RESPONSE" | grep -q '"success":true' && print_success "Portfolio updated" || print_error "Portfolio update failed"
    echo ""
fi

# Test 10: Create Watchlist Item
print_test "Create Watchlist Item"
WATCHLIST_RESPONSE=$(curl -s -X POST "$API_URL/watchlists" \
  -H "Content-Type: application/json" \
  -H "X-Device-Token: $DEVICE_TOKEN" \
  -d "{
    \"symbol\": \"AMD\",
    \"assetType\": \"stock\",
    \"exchange\": \"NASDAQ\",
    \"reason\": \"potential_buy\",
    \"notes\": \"Monitoring for entry point\",
    \"priority\": 7
  }")

echo "$WATCHLIST_RESPONSE"
WATCHLIST_ID=$(echo "$WATCHLIST_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$WATCHLIST_ID" ]; then
    print_success "Watchlist item created (ID: $WATCHLIST_ID)"
else
    print_error "Watchlist creation failed"
fi
echo ""

# Test 11: Get All Watchlists
print_test "Get All Watchlist Items"
GET_WATCHLISTS_RESPONSE=$(curl -s -X GET "$API_URL/watchlists" \
  -H "X-Device-Token: $DEVICE_TOKEN")

echo "$GET_WATCHLISTS_RESPONSE"
echo "$GET_WATCHLISTS_RESPONSE" | grep -q '"success":true' && print_success "Get watchlists successful" || print_error "Get watchlists failed"
echo ""

# Test 12: Create Strategy
print_test "Create Investment Strategy"
STRATEGY_RESPONSE=$(curl -s -X POST "$API_URL/strategies" \
  -H "Content-Type: application/json" \
  -H "X-Device-Token: $DEVICE_TOKEN" \
  -d "{
    \"name\": \"NVDA突破加仓策略\",
    \"description\": \"当NVDA突破\$900时加仓\",
    \"symbol\": \"NVDA\",
    \"conditionType\": \"price\",
    \"conditions\": {
      \"priceAbove\": 900
    },
    \"action\": {
      \"type\": \"buy\",
      \"amount\": 20,
      \"reason\": \"技术突破确认，上升趋势确立\"
    },
    \"reasoning\": \"NVDA在AI芯片领域领先\",
    \"priority\": 8
  }")

echo "$STRATEGY_RESPONSE"
STRATEGY_ID=$(echo "$STRATEGY_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$STRATEGY_ID" ]; then
    print_success "Strategy created (ID: $STRATEGY_ID)"
else
    print_error "Strategy creation failed"
fi
echo ""

# Test 13: Get All Strategies
print_test "Get All Strategies"
GET_STRATEGIES_RESPONSE=$(curl -s -X GET "$API_URL/strategies" \
  -H "X-Device-Token: $DEVICE_TOKEN")

echo "$GET_STRATEGIES_RESPONSE"
echo "$GET_STRATEGIES_RESPONSE" | grep -q '"success":true' && print_success "Get strategies successful" || print_error "Get strategies failed"
echo ""

# Test 14: Create Temporary Focus
print_test "Create Temporary Focus"
TEMP_FOCUS_RESPONSE=$(curl -s -X POST "$API_URL/temporary-focus" \
  -H "Content-Type: application/json" \
  -H "X-Device-Token: $DEVICE_TOKEN" \
  -d "{
    \"title\": \"关注AMD财报对NVDA的影响\",
    \"description\": \"AMD发布财报，观察对NVDA股价的影响\",
    \"targets\": [
      {\"symbol\": \"AMD\", \"type\": \"stock\"},
      {\"symbol\": \"NVDA\", \"type\": \"stock\"}
    ],
    \"focus\": {
      \"newsImpact\": true,
      \"priceReaction\": true
    },
    \"expiresAt\": \"$(date -u -d '+7 days' +%Y-%m-%dT%H:%M:%SZ)\"
  }")

echo "$TEMP_FOCUS_RESPONSE"
TEMP_FOCUS_ID=$(echo "$TEMP_FOCUS_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$TEMP_FOCUS_ID" ]; then
    print_success "Temporary focus created (ID: $TEMP_FOCUS_ID)"
else
    print_error "Temporary focus creation failed"
fi
echo ""

# Test 15: Get All Temporary Focus Items
print_test "Get All Temporary Focus Items"
GET_TEMP_FOCUS_RESPONSE=$(curl -s -X GET "$API_URL/temporary-focus" \
  -H "X-Device-Token: $DEVICE_TOKEN")

echo "$GET_TEMP_FOCUS_RESPONSE"
echo "$GET_TEMP_FOCUS_RESPONSE" | grep -q '"success":true' && print_success "Get temporary focus successful" || print_error "Get temporary focus failed"
echo ""

# Test 16: Test Error Handling - Invalid Portfolio
print_test "Error Handling - Invalid Portfolio Data"
INVALID_PORTFOLIO_RESPONSE=$(curl -s -X POST "$API_URL/portfolios" \
  -H "Content-Type: application/json" \
  -H "X-Device-Token: $DEVICE_TOKEN" \
  -d "{
    \"symbol\": \"\",
    \"shares\": -1
  }")

echo "$INVALID_PORTFOLIO_RESPONSE"
echo "$INVALID_PORTFOLIO_RESPONSE" | grep -q '"success":false' && print_success "Error handling works correctly" || print_error "Error handling failed"
echo ""

# Test 17: Test Authentication Failure
print_test "Authentication Failure - No Token"
AUTH_FAIL_RESPONSE=$(curl -s -X GET "$API_URL/users/profile")

echo "$AUTH_FAIL_RESPONSE"
echo "$AUTH_FAIL_RESPONSE" | grep -q '"success":false' && print_success "Authentication check works" || print_error "Authentication check failed"
echo ""

# Test 18: Cleanup - Delete Temporary Focus
if [ -n "$TEMP_FOCUS_ID" ]; then
    print_test "Cleanup - Delete Temporary Focus"
    DELETE_TEMP_FOCUS_RESPONSE=$(curl -s -X DELETE "$API_URL/temporary-focus/$TEMP_FOCUS_ID" \
      -H "X-Device-Token: $DEVICE_TOKEN")

    echo "$DELETE_TEMP_FOCUS_RESPONSE"
    echo "$DELETE_TEMP_FOCUS_RESPONSE" | grep -q '"success":true' && print_success "Temporary focus deleted" || print_error "Delete failed"
    echo ""
fi

echo "=========================================="
echo "API Test Suite Complete"
echo "=========================================="
echo ""
echo "Test Data Created:"
echo "  User ID: $USER_ID"
echo "  Device Token: $DEVICE_TOKEN"
echo "  Portfolio ID: $PORTFOLIO_ID"
echo "  Watchlist ID: $WATCHLIST_ID"
echo "  Strategy ID: $STRATEGY_ID"
echo "  Temporary Focus ID: $TEMP_FOCUS_ID"
echo ""
echo "You can manually test these endpoints using:"
echo "  curl -H \"X-Device-Token: $DEVICE_TOKEN\" $API_URL/portfolios"
