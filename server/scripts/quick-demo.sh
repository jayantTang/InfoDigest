#!/bin/bash

# InfoDigest v2.0 快速演示
# 展示现有功能和数据

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

BASE_URL="http://localhost:3000"

echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  InfoDigest v2.0 功能展示                 ║${NC}"
echo -e "${CYAN}║  智能投资监控系统                         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

# 1. 系统健康
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}1️⃣  系统健康状态${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
curl -s "$BASE_URL/health" | jq '.'
echo ""

# 2. 监控引擎状态
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}2️⃣  监控引擎状态${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
MONITOR=$(curl -s "$BASE_URL/api/monitoring/status")
echo "$MONITOR" | jq '.'

# 提取监控运行状态
IS_RUNNING=$(echo "$MONITOR" | jq -r '.data.monitoring.isRunning')
QUEUE_SIZE=$(echo "$MONITOR" | jq -r '.data.pushQueue.queueSize')

if [ "$IS_RUNNING" = "true" ]; then
  echo -e "${GREEN}✓ 监控引擎正在运行${NC}"
else
  echo -e "${YELLOW}⚠️  监控引擎未运行${NC}"
fi
echo -e "${CYAN}队列中的通知: $QUEUE_SIZE${NC}"
echo ""

# 3. 激活的策略
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}3️⃣  查看激活的策略${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
STRATEGIES=$(curl -s "$BASE_URL/api/monitoring/strategies")
STRATEGY_COUNT=$(echo "$STRATEGIES" | jq -r '.data.count // 0')
echo "$STRATEGIES" | jq '.data.strategies[] | {
  名称: .name,
  股票: .symbol,
  条件类型: .condition_type,
  优先级: .priority,
  状态: .status
}'
echo -e "${CYAN}总策略数: $STRATEGY_COUNT${NC}"
echo ""

# 4. 数据采集状态
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}4️⃣  数据采集状态${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
COLLECTION_STATUS=$(curl -s "$BASE_URL/api/data-collection/status")
echo "$COLLECTION_STATUS" | jq '.'

# 采集器列表
COLLECTORS=$(echo "$COLLECTION_STATUS" | jq -r '.data.registeredCollectors[]' 2>/dev/null || echo "[]")
echo -e "${CYAN}已注册的采集器:${NC}"
for collector in $COLLECTORS; do
  echo -e "  • $collector"
done
echo ""

# 5. 数据源健康
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}5️⃣  数据源健康检查${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
HEALTH=$(curl -s "$BASE_URL/api/data-collection/health")
echo "$HEALTH" | jq '.'
echo ""

# 6. 市场事件
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}6️⃣  近期市场事件${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
EVENTS=$(curl -s "$BASE_URL/api/monitoring/events?limit=5")
EVENT_COUNT=$(echo "$EVENTS" | jq -r '.data.count // 0')
echo "$EVENTS" | jq '.data.events[]? | {
  标题: .title,
  分类: .category,
  重要性: .importance_score,
  已处理: .is_processed
}'
echo -e "${CYAN}事件总数: $EVENT_COUNT${NC}"
echo ""

# 7. 监控指标
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}7️⃣  监控指标统计${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
METRICS=$(curl -s "$BASE_URL/api/monitoring/metrics")
echo "$METRICS" | jq '.'
echo ""

# 8. AI分析统计
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}8️⃣  AI分析统计${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
ANALYSIS_STATS=$(curl -s "$BASE_URL/api/analysis/stats")
echo "$ANALYSIS_STATS" | jq '.'

# 提取统计信息
STRATEGY_ANALYSES=$(echo "$ANALYSIS_STATS" | jq -r '.data.strategyAnalyses.total_analyses // 0')
FOCUS_ANALYSES=$(echo "$ANALYSIS_STATS" | jq -r '.data.focusAnalyses.total_analyses // 0')
EVENT_ANALYSES=$(echo "$ANALYSIS_STATS" | jq -r '.data.eventAnalyses.total_analyses // 0')

echo ""
echo -e "${CYAN}策略分析: $STRATEGY_ANALYSES${NC}"
echo -e "${CYAN}关注分析: $FOCUS_ANALYSES${NC}"
echo -e "${CYAN}事件分析: $EVENT_ANALYSES${NC}"
echo ""

# 9. 推送队列状态
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}9️⃣  推送队列状态${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
QUEUE=$(curl -s "$BASE_URL/api/monitoring/queue")
echo "$QUEUE" | jq '.'
echo ""

# 总结
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 系统功能总结${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}✅ 核心功能:${NC}"
echo -e "  • 实时监控引擎（每60秒）"
echo -e "  • 多源数据采集（6个数据源）"
echo -e "  • 智能事件评分（0-100分）"
echo -e "  • 优先级推送队列"
echo -e "  • AI驱动分析（DeepSeek/OpenAI）"
echo ""
echo -e "${GREEN}✅ API端点:${NC}"
echo -e "  • 数据采集: 6个端点"
echo -e "  • 监控管理: 12个端点"
echo -e "  • AI分析: 13个端点"
echo -e "  • 用户管理: 10个端点"
echo -e "  • 投资组合: 8个端点"
echo ""
echo -e "${YELLOW}💡 使用建议:${NC}"
echo -e "  1. 通过API或iOS客户端注册设备"
echo -e "  2. 创建投资组合和关注列表"
echo -e "  3. 设置自定义监控策略"
echo -e "  4. 系统自动监控并发送通知"
echo -e "  5. 查看AI生成的深度分析"
echo ""
echo -e "${CYAN}📚 查看完整文档:${NC}"
echo -e "  docs/PHASE1_COMPLETION.md - 用户配置系统"
echo -e "  docs/PHASE2_COMPLETION.md - 数据采集系统"
echo -e "  docs/PHASE3_COMPLETION.md - 监控引擎"
echo -e "  docs/PHASE4_COMPLETION.md - LLM分析系统"
echo ""
echo -e "${GREEN}InfoDigest v2.0 - 智能投资监控系统${NC}"
echo ""
