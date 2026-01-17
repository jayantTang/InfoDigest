#!/bin/bash

# InfoDigest 测试推送脚本

echo "=== 发送测试推送通知 ==="
echo ""

# 检查服务器
if ! curl -s http://localhost:3000/health > /dev/null; then
    echo "❌ 服务器未运行"
    echo "请先启动服务器：./scripts/start-server.sh"
    exit 1
fi

# 发送推送
echo "📤 发送测试推送..."
RESPONSE=$(curl -X POST http://localhost:3000/api/admin/test-push \
  -H "Content-Type: application/json" \
  -H "X-API-Key: dev-admin-key-12345" \
  -d '{"title":"🎉 测试推送","message":"这是一条测试消息"}' \
  -s)

echo ""
echo "服务器响应："
echo "$RESPONSE" | jq .

# 检查响应
if echo "$RESPONSE" | jq -e '.data.success' > /dev/null 2>&1; then
    SUCCESS=$(echo "$RESPONSE" | jq -r '.data.success')
    if [ "$SUCCESS" -gt 0 ]; then
        echo ""
        echo "✅ 推送发送成功！"
        echo "请检查您的iPhone是否收到通知。"
    else
        echo ""
        echo "⚠️  推送发送失败"
    fi
fi
