#!/bin/bash

# InfoDigest v2.0 用户体验指南
# 逐步引导体验完整功能

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="http://localhost:3000"
API_KEY="dev-admin-key-12345"

# 保存用户ID
USER_ID=""
DEVICE_ID=""

echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  InfoDigest v2.0 用户体验指南           ║${NC}"
echo -e "${CYAN}║  智能投资监控系统                         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

# 步骤1: 检查服务器状态
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}步骤 1: 检查系统状态${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

HEALTH_RESPONSE=$(curl -s "$BASE_URL/health")
echo -e "📊 服务器健康状态:"
echo "$HEALTH_RESPONSE" | jq '.'

echo ""
echo -e "${GREEN}✓ 系统正常运行${NC}"
echo ""
read -p "按 Enter 继续下一步..."

# 步骤2: 注册iOS设备
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}步骤 2: 注册iOS设备${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "模拟注册一个iOS设备（模拟器）..."
echo ""

DEVICE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/devices/register" \
  -H "Content-Type: application/json" \
  -d '{
    "device_token": "test-device-token-001",
    "platform": "ios",
    "app_version": "1.0.0",
    "os_version": "17.0"
  }')

echo "$DEVICE_RESPONSE" | jq '.'

# 提取用户ID和设备ID
USER_ID=$(echo "$DEVICE_RESPONSE" | jq -r '.data.userId // empty')
DEVICE_ID=$(echo "$DEVICE_RESPONSE" | jq -r '.data.deviceId // empty')

echo ""
echo -e "${GREEN}✓ 设备注册成功${NC}"
echo -e "   用户ID: ${CYAN}$USER_ID${NC}"
echo -e "   设备ID: ${CYAN}$DEVICE_ID${NC}"
echo ""
read -p "按 Enter 继续下一步..."

# 步骤3: 配置用户偏好
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}步骤 3: 配置用户偏好${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "设置推送通知和默认配置..."
echo ""

PREFS_RESPONSE=$(curl -s -X PUT "$BASE_URL/api/users/$USER_ID/preferences" \
  -H "Content-Type: application/json" \
  -d '{
    "pushEnabled": true,
    "timezone": "Asia/Shanghai",
    "currency": "USD",
    "language": "zh-CN",
    "notifications": {
      "strategies": true,
      "focusItems": true,
      "marketEvents": true,
      "dailyDigest": true
    }
  }')

echo "$PREFS_RESPONSE" | jq '.'

echo ""
echo -e "${GREEN}✓ 用户偏好配置完成${NC}"
echo ""
read -p "按 Enter 继续下一步..."

# 步骤4: 创建投资组合
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}步骤 4: 创建投资组合${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "添加一些热门科技股到您的投资组合..."
echo ""

PORTFOLIO_RESPONSE=$(curl -s -X POST "$BASE_URL/api/portfolios/items" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"symbol\": \"NVDA\",
    \"shares\": 10,
    \"averageCost\": 450.00,
    \"assetType\": \"stock\"
  }")

echo "$PORTFOLIO_RESPONSE" | jq '.'

# 添加更多股票
echo ""
echo -e "添加更多股票..."

curl -s -X POST "$BASE_URL/api/portfolios/items" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"symbol\": \"AAPL\",
    \"shares\": 50,
    \"averageCost\": 175.00,
    \"assetType\": \"stock\"
  }" > /dev/null

curl -s -X POST "$BASE_URL/api/portfolios/items" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"symbol\": \"MSFT\",
    \"shares\": 30,
    \"averageCost\": 380.00,
    \"assetType\": \"stock\"
  }" > /dev/null

echo ""
echo -e "${GREEN}✓ 投资组合创建完成${NC}"
echo ""
read -p "按 Enter 继续下一步..."

# 步骤5: 创建关注列表
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}步骤 5: 创建关注列表${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "添加一些感兴趣的股票到关注列表..."
echo ""

WATCHLIST_RESPONSE=$(curl -s -X POST "$BASE_URL/api/watchlists/items" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"symbol\": \"TSLA\",
    \"notes\": \"电动汽车领头羊\"
  }")

echo "$WATCHLIST_RESPONSE" | jq '.'

# 添加更多
curl -s -X POST "$BASE_URL/api/watchlists/items" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"symbol\": \"GOOGL\",
    \"notes\": \"搜索和云服务\"
  }" > /dev/null

curl -s -X POST "$BASE_URL/api/watchlists/items" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"symbol\": \"AMZN\",
    \"notes\": \"电商和云计算\"
  }" > /dev/null

echo ""
echo -e "${GREEN}✓ 关注列表创建完成${NC}"
echo ""
read -p "按 Enter 继续下一步..."

# 步骤6: 创建价格策略
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}步骤 6: 创建价格监控策略${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "为NVDA设置价格突破策略..."
echo ""

STRATEGY_RESPONSE=$(curl -s -X POST "$BASE_URL/api/strategies" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"symbol\": \"NVDA\",
    \"name\": \"NVDA突破900美元\",
    \"conditionType\": \"price\",
    \"conditions\": {
      \"priceAbove\": 900
    },
    \"action\": \"notify\",
    \"priority\": 70
  }")

echo "$STRATEGY_RESPONSE" | jq '.'

STRATEGY_ID=$(echo "$STRATEGY_RESPONSE" | jq -r '.data.strategy.id // empty')

echo ""
echo -e "${GREEN}✓ 价格策略创建完成${NC}"
echo -e "   策略ID: ${CYAN}$STRATEGY_ID${NC}"
echo ""
read -p "按 Enter 继续下一步..."

# 步骤7: 创建技术指标策略
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}步骤 7: 创建技术指标策略${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "为AAPL设置RSI超卖策略..."
echo ""

TECH_STRATEGY_RESPONSE=$(curl -s -X POST "$BASE_URL/api/strategies" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"symbol\": \"AAPL\",
    \"name\": \"AAPL RSI超卖信号\",
    \"conditionType\": \"technical\",
    \"conditions\": {
      \"rsi\": {
        \"below\": 30
      }
    },
    \"action\": \"notify\",
    \"priority\": 75
  }")

echo "$TECH_STRATEGY_RESPONSE" | jq '.'

echo ""
echo -e "${GREEN}✓ 技术策略创建完成${NC}"
echo ""
read -p "按 Enter 继续下一步..."

# 步骤8: 创建临时关注
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}步骤 8: 创建临时关注${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "创建一个7天的科技股临时关注..."
echo ""

FOCUS_RESPONSE=$(curl -s -X POST "$BASE_URL/api/temporary-focus" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"title\": \"科技股短期监控\",
    \"description\": \"监控主要科技股的价格异动和重要新闻\",
    \"targets\": [\"NVDA\", \"AAPL\", \"MSFT\", \"TSLA\"],
    \"focus\": {
      \"newsImpact\": true,
      \"priceReaction\": true,
      \"correlation\": false
    },
    \"expiresAt\": \"2026-01-25T23:59:59Z\"
  }")

echo "$FOCUS_RESPONSE" | jq '.'

FOCUS_ID=$(echo "$FOCUS_RESPONSE" | jq -r '.data.focusItem.id // empty')

echo ""
echo -e "${GREEN}✓ 临时关注创建完成${NC}"
echo -e "   关注ID: ${CYAN}$FOCUS_ID${NC}"
echo ""
read -p "按 Enter 继续下一步..."

# 步骤9: 触发数据采集
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}步骤 9: 触发数据采集${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "开始采集市场数据（这可能需要1-2分钟）..."
echo ""

COLLECT_RESPONSE=$(curl -s -X POST "$BASE_URL/api/data-collection/collect-all" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY")

echo "$COLLECT_RESPONSE" | jq '.'

echo ""
echo -e "${YELLOW}⏳ 等待数据采集完成...${NC}"
sleep 5

echo ""
echo -e "${GREEN}✓ 数据采集已触发${NC}"
echo -e "   ${YELLOW}注意: 采集正在后台进行，请稍后查看结果${NC}"
echo ""
read -p "按 Enter 继续下一步..."

# 步骤10: 查看投资组合
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}步骤 10: 查看您的投资组合${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

PORTFOLIO_GET=$(curl -s "$BASE_URL/api/portfolios?user_id=$USER_ID")

echo -e "📊 您的投资组合:"
echo "$PORTFOLIO_GET" | jq '.data.items[] | {
  symbol: .symbol,
  shares: .shares,
  averageCost: .averageCost,
  currentPrice: .current_price // "N/A"
}'

echo ""
read -p "按 Enter 继续下一步..."

# 步骤11: 查看策略列表
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}步骤 11: 查看您的策略${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

STRATEGIES_GET=$(curl -s "$BASE_URL/api/strategies?user_id=$USER_ID")

echo -e "🎯 您的策略列表:"
echo "$STRATEGIES_GET" | jq '.data.strategies[] | {
  name: .name,
  symbol: .symbol,
  conditionType: .condition_type,
  priority: .priority,
  status: .status
}'

echo ""
read -p "按 Enter 继续下一步..."

# 步骤12: 查看监控状态
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}步骤 12: 查看监控引擎状态${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

MONITOR_STATUS=$(curl -s "$BASE_URL/api/monitoring/status")

echo -e "🔍 监控引擎状态:"
echo "$MONITOR_STATUS" | jq '.'

echo ""
read -p "按 Enter 继续下一步..."

# 步骤13: 手动触发监控检查
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}步骤 13: 手动触发监控检查${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "立即执行一次监控周期..."
echo ""

CHECK_RESPONSE=$(curl -s -X POST "$BASE_URL/api/monitoring/check-cycle" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY")

echo "$CHECK_RESPONSE" | jq '.'

echo ""
echo -e "${GREEN}✓ 监控检查完成${NC}"
echo ""
read -p "按 Enter 继续下一步..."

# 步骤14: 生成LLM分析
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}步骤 14: 生成AI分析${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "为您的NVDA策略生成AI分析（可能需要10-20秒）..."
echo ""

if [ -n "$STRATEGY_ID" ]; then
  ANALYSIS_RESPONSE=$(curl -s -X POST "$BASE_URL/api/analysis/strategy/$STRATEGY_ID/generate" \
    -H "Content-Type: application/json" \
    -H "X-API-Key: $API_KEY")

  echo "$ANALYSIS_RESPONSE" | jq '.'
else
  echo -e "${YELLOW}⚠️  策略ID未找到，跳过分析生成${NC}"
fi

echo ""
echo -e "${GREEN}✓ AI分析生成请求已提交${NC}"
echo ""
read -p "按 Enter 继续下一步..."

# 步骤15: 查看系统统计
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}步骤 15: 查看系统统计${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "📈 监控指标:"
METRICS=$(curl -s "$BASE_URL/api/monitoring/metrics")
echo "$METRICS" | jq '.'

echo ""
echo -e "📊 数据采集健康:"
HEALTH=$(curl -s "$BASE_URL/api/data-collection/health")
echo "$HEALTH" | jq '.'

echo ""
echo -e "🤖 AI分析统计:"
ANALYSIS_STATS=$(curl -s "$BASE_URL/api/analysis/stats")
echo "$ANALYSIS_STATS" | jq '.'

# 完成总结
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}🎉 体验完成！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}您已成功体验了以下功能:${NC}"
echo ""
echo -e "  ✅ 设备注册和用户管理"
echo -e "  ✅ 用户偏好配置"
echo -e "  ✅ 投资组合管理（添加了NVDA、AAPL、MSFT）"
echo -e "  ✅ 关注列表管理（添加了TSLA、GOOGL、AMZN）"
echo -e "  ✅ 价格策略设置（NVDA突破$900）"
echo -e "  ✅ 技术指标策略（AAPL RSI超卖）"
echo -e "  ✅ 临时关注项目（科技股监控）"
echo -e "  ✅ 数据采集触发"
echo -e "  ✅ 监控引擎检查"
echo -e "  ✅ AI分析生成"
echo ""
echo -e "${CYAN}接下来您可以:${NC}"
echo ""
echo -e "  1. 📱 在iOS设备上接收推送通知"
echo -e "  2. 📊 定期查看投资组合表现"
echo -e "  3. 🎯 调整和优化策略"
echo -e "  4. 🔍 查看AI生成的分析报告"
echo -e "  5. 📰 关注市场事件和新闻"
echo ""
echo -e "${YELLOW}💡 提示:${NC}"
echo -e "  - 监控引擎每60秒自动检查一次"
echo -e "  - 数据采集根据配置定时执行"
echo -e "  - AI分析会在策略触发时自动生成"
echo -e "  - 推送通知会立即发送到您的设备"
echo ""
echo -e "${CYAN}您的用户ID: ${USER_ID}${NC}"
echo -e "${CYAN}您的设备ID: ${DEVICE_ID}${NC}"
echo ""
echo -e "${GREEN}感谢体验 InfoDigest v2.0！${NC}"
echo ""
