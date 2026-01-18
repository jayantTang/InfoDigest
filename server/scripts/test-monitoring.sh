#!/bin/bash

# Test script for InfoDigest v2.0 Monitoring Engine
# Tests monitoring engine, push notification queue, and event scoring

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
echo -e "${GREEN}InfoDigest v2.0 Monitoring Engine Test${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to make API calls and check results
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
echo -e "${YELLOW}1. Testing Monitoring Engine Status${NC}"
echo "-------------------------------------------"

test_get "Monitoring engine status" \
  "/api/monitoring/status" \
  ".success" \
  "true"

echo ""
echo -e "${YELLOW}2. Testing Push Notification Queue${NC}"
echo "-------------------------------------------"

test_get "Push queue status" \
  "/api/monitoring/queue" \
  ".success" \
  "true"

echo ""
echo -e "${YELLOW}3. Testing Active Strategies Query${NC}"
echo "-------------------------------------------"

test_get "Get active strategies" \
  "/api/monitoring/strategies" \
  ".success" \
  "true"

echo ""
echo -e "${YELLOW}4. Testing Temporary Focus Items${NC}"
echo "-------------------------------------------"

test_get "Get focus items" \
  "/api/monitoring/focus-items" \
  ".success" \
  "true"

echo ""
echo -e "${YELLOW}5. Testing Market Events${NC}"
echo "-------------------------------------------"

test_get "Get market events" \
  "/api/monitoring/events?limit=10" \
  ".success" \
  "true"

echo ""
echo -e "${YELLOW}6. Testing Monitoring Metrics${NC}"
echo "-------------------------------------------"

test_get "Monitoring metrics" \
  "/api/monitoring/metrics" \
  ".success" \
  "true"

echo ""
echo -e "${YELLOW}7. Testing Manual Monitoring Control${NC}"
echo "-------------------------------------------"

# Start monitoring engine
test_post "Start monitoring engine" \
  "/api/monitoring/start" \
  '{}' \
  ".success" \
  "true"

sleep 2

# Check status again
test_get "Verify monitoring is running" \
  "/api/monitoring/status" \
  ".data.monitoring.isRunning" \
  "true"

# Trigger manual check cycle
test_post "Trigger manual check cycle" \
  "/api/monitoring/check-cycle" \
  '{}' \
  ".success" \
  "true"

sleep 3

# Stop monitoring engine
test_post "Stop monitoring engine" \
  "/api/monitoring/stop" \
  '{}' \
  ".success" \
  "true"

sleep 1

# Verify stopped
test_get "Verify monitoring is stopped" \
  "/api/monitoring/status" \
  ".data.monitoring.isRunning" \
  "false"

echo ""
echo -e "${YELLOW}8. Testing Push Queue Management${NC}"
echo "-------------------------------------------"

# Clear queue
test_post "Clear push queue" \
  "/api/monitoring/queue/clear" \
  '{}' \
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
