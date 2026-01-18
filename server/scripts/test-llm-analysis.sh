#!/bin/bash

# Test script for InfoDigest v2.0 LLM Analysis Service
# Tests AI-powered analysis generation

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="http://localhost:3000"
API_KEY="dev-admin-key-12345"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}InfoDigest v2.0 LLM Analysis Test${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to make API calls
test_api() {
  local test_name="$1"
  local method="$2"
  local endpoint="$3"
  local data="$4"
  local expected_field="$5"
  local expected_value="$6"

  echo -n "Testing: $test_name ... "

  local response
  local status_code

  if [ -z "$data" ]; then
    response=$(curl -s -w "\n%{http_code}" -X "$method" \
      "$BASE_URL$endpoint" \
      -H "Content-Type: application/json")
  else
    response=$(curl -s -w "\n%{http_code}" -X "$method" \
      "$BASE_URL$endpoint" \
      -H "Content-Type: application/json" \
      -H "X-API-Key: $API_KEY" \
      -d "$data")
  fi

  # Split response and status code
  status_code=$(echo "$response" | tail -n1)
  body=$(echo "$response" | sed '$d')

  # Check if status code is 2xx
  if [[ $status_code =~ ^2 ]]; then
    if [ -n "$expected_field" ]; then
      # Check if expected field exists and has expected value
      if echo "$body" | jq -e "$expected_field == $expected_value" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
      else
        echo -e "${RED}✗ FAIL${NC}"
        echo "  Expected: $expected_field == $expected_value"
        echo "  Response: $body"
        TESTS_FAILED=$((TESTS_FAILED + 1))
      fi
    else
      echo -e "${GREEN}✓ PASS${NC}"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
  else
    echo -e "${RED}✗ FAIL${NC}"
    echo "  Status Code: $status_code"
    echo "  Response: $body"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# Helper function to test GET requests
test_get() {
  local test_name="$1"
  local endpoint="$2"
  local expected_field="$3"
  local expected_value="$4"

  test_api "$test_name" "GET" "$endpoint" "" "$expected_field" "$expected_value"
}

# Helper function to test POST requests
test_post() {
  local test_name="$1"
  local endpoint="$2"
  local data="$3"
  local expected_field="$4"
  local expected_value="$5"

  test_api "$test_name" "POST" "$endpoint" "$data" "$expected_field" "$expected_value"
}

# Start testing
echo -e "${YELLOW}1. Testing Analysis Statistics${NC}"
echo "-------------------------------------------"

test_get "Analysis statistics" \
  "/api/analysis/stats" \
  ".success" \
  "true"

echo ""
echo -e "${YELLOW}2. Testing Strategy Analysis APIs${NC}"
echo "-------------------------------------------"

# Get a strategy ID first
STRATEGY_RESPONSE=$(curl -s "$BASE_URL/api/monitoring/strategies?limit=1")
STRATEGY_ID=$(echo "$STRATEGY_RESPONSE" | jq -r '.data.strategies[0].id // empty')

if [ -n "$STRATEGY_ID" ] && [ "$STRATEGY_ID" != "null" ]; then
  echo -e "${GREEN}Found strategy ID: $STRATEGY_ID${NC}"

  test_get "Get strategy analysis" \
    "/api/analysis/strategy/$STRATEGY_ID" \
    ".success" \
    "true"

  echo ""
  echo -e "${YELLOW}Generating strategy analysis (may take 10-20 seconds)...${NC}"

  # Start analysis generation in background
  POST_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "$BASE_URL/api/analysis/strategy/$STRATEGY_ID/generate" \
    -H "Content-Type: application/json" \
    -H "X-API-Key: $API_KEY")

  POST_STATUS=$(echo "$POST_RESPONSE" | tail -n1)
  POST_BODY=$(echo "$POST_RESPONSE" | sed '$d')

  if [[ $POST_STATUS =~ ^2 ]]; then
    echo -e "${GREEN}✓ PASS${NC} - Analysis generation initiated"

    # Wait for analysis to complete
    echo "Waiting for analysis to complete..."
    sleep 15

    # Check if analysis was created
    test_get "Verify strategy analysis created" \
      "/api/analysis/strategy/$STRATEGY_ID" \
      ".success" \
      "true"
  else
    echo -e "${RED}✗ FAIL${NC} - Failed to generate analysis"
    echo "  Status: $POST_STATUS"
    echo "  Response: $POST_BODY"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
else
  echo -e "${YELLOW}⚠ SKIP${NC} - No strategies found to test"
  echo "  Create a strategy first to test analysis generation"
fi

echo ""
echo -e "${YELLOW}3. Testing Focus Analysis APIs${NC}"
echo "-------------------------------------------"

# Get a focus item ID
FOCUS_RESPONSE=$(curl -s "$BASE_URL/api/monitoring/focus-items?limit=1")
FOCUS_ID=$(echo "$FOCUS_RESPONSE" | jq -r '.data.focusItems[0].id // empty')

if [ -n "$FOCUS_ID" ] && [ "$FOCUS_ID" != "null" ]; then
  echo -e "${GREEN}Found focus item ID: $FOCUS_ID${NC}"

  test_get "Get focus analysis" \
    "/api/analysis/focus/$FOCUS_ID" \
    ".success" \
    "true"

  echo ""
  echo -e "${YELLOW}Generating focus analysis (may take 10-20 seconds)...${NC}"

  # Start analysis generation in background
  POST_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "$BASE_URL/api/analysis/focus/$FOCUS_ID/generate" \
    -H "Content-Type: application/json" \
    -H "X-API-Key: $API_KEY")

  POST_STATUS=$(echo "$POST_RESPONSE" | tail -n1)
  POST_BODY=$(echo "$POST_RESPONSE" | sed '$d')

  if [[ $POST_STATUS =~ ^2 ]]; then
    echo -e "${GREEN}✓ PASS${NC} - Analysis generation initiated"

    # Wait for analysis to complete
    echo "Waiting for analysis to complete..."
    sleep 15

    # Check if analysis was created
    test_get "Verify focus analysis created" \
      "/api/analysis/focus/$FOCUS_ID" \
      ".success" \
      "true"
  else
    echo -e "${RED}✗ FAIL${NC} - Failed to generate analysis"
    echo "  Status: $POST_STATUS"
    echo "  Response: $POST_BODY"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
else
  echo -e "${YELLOW}⚠ SKIP${NC} - No focus items found to test"
  echo "  Create a focus item first to test analysis generation"
fi

echo ""
echo -e "${YELLOW}4. Testing Event Analysis APIs${NC}"
echo "-------------------------------------------"

# Get an event ID
EVENT_RESPONSE=$(curl -s "$BASE_URL/api/monitoring/events?limit=1")
EVENT_ID=$(echo "$EVENT_RESPONSE" | jq -r '.data.events[0].id // empty')

if [ -n "$EVENT_ID" ] && [ "$EVENT_ID" != "null" ]; then
  echo -e "${GREEN}Found event ID: $EVENT_ID${NC}"

  test_get "Get event analysis" \
    "/api/analysis/event/$EVENT_ID" \
    ".success" \
    "true"

  echo ""
  echo -e "${YELLOW}Generating event analysis (may take 10-20 seconds)...${NC}"

  # Start analysis generation in background
  POST_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "$BASE_URL/api/analysis/event/$EVENT_ID/generate" \
    -H "Content-Type: application/json" \
    -H "X-API-Key: $API_KEY")

  POST_STATUS=$(echo "$POST_RESPONSE" | tail -n1)
  POST_BODY=$(echo "$POST_RESPONSE" | sed '$d')

  if [[ $POST_STATUS =~ ^2 ]]; then
    echo -e "${GREEN}✓ PASS${NC} - Analysis generation initiated"

    # Wait for analysis to complete
    echo "Waiting for analysis to complete..."
    sleep 15

    # Check if analysis was created
    test_get "Verify event analysis created" \
      "/api/analysis/event/$EVENT_ID" \
      ".success" \
      "true"
  else
    echo -e "${RED}✗ FAIL${NC} - Failed to generate analysis"
    echo "  Status: $POST_STATUS"
    echo "  Response: $POST_BODY"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
else
  echo -e "${YELLOW}⚠ SKIP${NC} - No events found to test"
  echo "  Events will be created when news is collected"
fi

echo ""
echo -e "${YELLOW}5. Testing Event Analysis List${NC}"
echo "-------------------------------------------"

test_get "Get all event analyses" \
  "/api/analysis/events?limit=10" \
  ".success" \
  "true"

echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Test Summary${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo -e "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}All tests passed! ✓${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed! ✗${NC}"
  exit 1
fi
