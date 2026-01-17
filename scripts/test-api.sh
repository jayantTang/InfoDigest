#!/bin/bash

# InfoDigest API测试脚本

echo "=== InfoDigest API 测试 ==="
echo ""

BASE_URL="http://localhost:3000"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试函数
test_endpoint() {
    local name=$1
    local method=$2
    local endpoint=$3
    local data=$4

    echo -n "测试 $name... "

    if [ -z "$data" ]; then
        response=$(curl -s -X "$method" "$BASE_URL$endpoint")
    else
        response=$(curl -s -X "$method" "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    fi

    if echo "$response" | jq -e '.success' > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        echo -e "  ${YELLOW}响应: $response${NC}"
        return 1
    fi
}

# 运行测试
echo "1. 健康检查"
test_endpoint "健康检查" "GET" "/health" ""

echo ""
echo "2. API端点测试"
test_endpoint "获取消息" "GET" "/api/messages?limit=1" ""
test_endpoint "获取设备" "GET" "/api/devices" ""

echo ""
echo "3. 管理端点测试"
test_endpoint "手动触发摘要" "POST" "/api/admin/run-digest" "" \
    -H "X-API-Key: dev-admin-key-12345"

echo ""
echo "=== 测试完成 ==="
