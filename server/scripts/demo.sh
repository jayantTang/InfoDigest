#!/bin/bash

# InfoDigest v2.0 自动演示
# 自动展示所有功能（无需交互）

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

BASE_URL="http://localhost:3000"
API_KEY="dev-admin-key-12345"

echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  InfoDigest v2.0 完整演示                 ║${NC}"
echo -e "${CYAN}║  智能投资监控系统                         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

# 1. 系统状态
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}1️⃣  系统状态检查${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
curl -s "$BASE_URL/health" | jq '.'
echo ""
sleep 1

# 2. 注册设备
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}2️⃣  注册iOS设备${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
DEVICE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/devices/register" \
  -H "Content-Type: application/json" \
  -d '{
    "device_token": "demo-device-001",
    "platform": "ios",
    "app_version": "1.0.0",
    "os_version": "17.0"
  }')
echo "$DEVICE_RESPONSE" | jq '.'
USER_ID=$(echo "$DEVICE_RESPONSE" | jq -r '.data.userId')
echo -e "${CYAN}用户ID: $USER_ID${NC}"
echo ""
sleep 1

# 3. 配置偏好
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}3️⃣  配置用户偏好${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
curl -s -X PUT "$BASE_URL/api/users/$USER_ID/preferences" \
  -H "Content-Type: application/json" \
  -d '{
    "pushEnabled": true,
    "timezone": "Asia/Shanghai",
    "currency": "USD"
  }' | jq '.'
echo ""
sleep 1

# 4. 创建投资组合
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}4️⃣  创建投资组合${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
curl -s -X POST "$BASE_URL/api/portfolios/items" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"symbol\": \"NVDA\",
    \"shares\": 10,
    \"averageCost\": 450.00
  }" | jq '.'

curl -s -X POST "$BASE_URL/api/portfolios/items" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"symbol\": \"AAPL\",
    \"shares\": 50,
    \"averageCost\": 175.00
  }" > /dev/null

curl -s -X POST "$BASE_URL/api/portfolios/items" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"symbol\": \"MSFT\",
    \"shares\": 30,
    \"averageCost\": 380.00
  }" > /dev/null
echo -e "${CYAN}已添加: NVDA (10股), AAPL (50股), MSFT (30股)${NC}"
echo ""
sleep 1

# 5. 创建关注列表
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}5️⃣  创建关注列表${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
curl -s -X POST "$BASE_URL/api/watchlists/items" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"symbol\": \"TSLA\",
    \"notes\": \"电动汽车领头羊\"
  }" | jq '.'

curl -s -X POST "$BASE_URL/api/watchlists/items" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"symbol\": \"GOOGL\"
  }" > /dev/null

curl -s -X POST "$BASE_URL/api/watchlists/items" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"symbol\": \"AMZN\"
  }" > /dev/null
echo -e "${CYAN}已添加: TSLA, GOOGL, AMZN${NC}"
echo ""
sleep 1

# 6. 创建策略
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}6️⃣  创建监控策略${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 价格策略
STRATEGY1=$(curl -s -X POST "$BASE_URL/api/strategies" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"symbol\": \"NVDA\",
    \"name\": \"NVDA突破900美元\",
    \"conditionType\": \"price\",
    \"conditions\": {\"priceAbove\": 900},
    \"priority\": 70
  }")
echo "$STRATEGY1" | jq '.'
STRATEGY_ID=$(echo "$STRATEGY1" | jq -r '.data.strategy.id')

# 技术策略
STRATEGY2=$(curl -s -X POST "$BASE_URL/api/strategies" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"symbol\": \"AAPL\",
    \"name\": \"AAPL RSI超卖\",
    \"conditionType\": \"technical\",
    \"conditions\": {\"rsi\": {\"below\": 30}},
    \"priority\": 75
  }")
echo "$STRATEGY2" | jq '.'
echo ""
sleep 1

# 7. 创建临时关注
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}7️⃣  创建临时关注${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
FOCUS=$(curl -s -X POST "$BASE_URL/api/temporary-focus" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"title\": \"科技股监控\",
    \"description\": \"短期监控科技股异动\",
    \"targets\": [\"NVDA\", \"AAPL\", \"MSFT\"],
    \"focus\": {\"newsImpact\": true, \"priceReaction\": true},
    \"expiresAt\": \"2026-01-25T23:59:59Z\"
  }")
echo "$FOCUS" | jq '.'
echo ""
sleep 1

# 8. 触发数据采集
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}8️⃣  触发数据采集${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}正在采集市场数据...${NC}"
COLLECT=$(curl -s -X POST "$BASE_URL/api/data-collection/collect-all" \
  -H "X-API-Key: $API_KEY")
echo "$COLLECT" | jq '.'
echo ""
sleep 3

# 9. 查看投资组合
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}9️⃣  查看投资组合${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
PORTFOLIO=$(curl -s "$BASE_URL/api/portfolios?user_id=$USER_ID")
echo "$PORTFOLIO" | jq '.data.items[] | {
  股票代码: .symbol,
  持仓数量: .shares,
  平均成本: .averageCost,
  当前价格: (.current_price // "N/A")
}'
echo ""
sleep 1

# 10. 查看策略
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🔟 查看策略列表${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
STRATEGIES=$(curl -s "$BASE_URL/api/strategies?user_id=$USER_ID")
echo "$STRATEGIES" | jq '.data.strategies[] | {
  名称: .name,
  股票: .symbol,
  类型: .condition_type,
  优先级: .priority,
  状态: .status
}'
echo ""
sleep 1

# 11. 监控状态
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}1️⃣1️⃣  监控引擎状态${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
MONITOR=$(curl -s "$BASE_URL/api/monitoring/status")
echo "$MONITOR" | jq '.'
echo ""
sleep 1

# 12. 手动监控检查
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}1️⃣2️⃣  执行监控检查${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
CHECK=$(curl -s -X POST "$BASE_URL/api/monitoring/check-cycle" \
  -H "X-API-Key: $API_KEY")
echo "$CHECK" | jq '.'
echo ""
sleep 1

# 13. 生成AI分析
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}1️⃣3️⃣  生成AI分析${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}正在生成AI分析（可能需要10-15秒）...${NC}"
if [ -n "$STRATEGY_ID" ]; then
  ANALYSIS=$(curl -s -X POST "$BASE_URL/api/analysis/strategy/$STRATEGY_ID/generate" \
    -H "X-API-Key: $API_KEY")
  echo "$ANALYSIS" | '.'
fi
echo ""
sleep 1

# 14. 系统统计
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}1️⃣4️⃣  系统统计${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${CYAN}📊 监控指标:${NC}"
curl -s "$BASE_URL/api/monitoring/metrics" | jq '.'

echo ""
echo -e "${CYAN}📈 数据采集健康:${NC}"
curl -s "$BASE_URL/api/data-collection/health" | jq '.'

echo ""
echo -e "${CYAN}🤖 AI分析统计:${NC}"
curl -s "$BASE_URL/api/analysis/stats" | jq '.'

# 总结
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 演示完成！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}已展示的功能:${NC}"
echo -e "  ✅ 设备注册和用户管理"
echo -e "  ✅ 投资组合管理（3只股票）"
echo -e "  ✅ 关注列表管理（3只股票）"
echo -e "  ✅ 监控策略（价格+技术指标）"
echo -e "  ✅ 临时关注项目"
echo -e "  ✅ 数据采集"
echo -e "  ✅ 监控引擎"
echo -e "  ✅ AI分析生成"
echo ""
echo -e "${CYAN}用户ID: $USER_ID${NC}"
echo ""
echo -e "${YELLOW}💡 提示:${NC}"
echo -e "  - 监控引擎每60秒自动运行"
echo -e "  - 推送通知会发送到iOS设备"
echo -e "  - AI分析会在策略触发时自动生成"
echo ""
echo -e "${GREEN}感谢体验 InfoDigest v2.0！${NC}"
echo ""
