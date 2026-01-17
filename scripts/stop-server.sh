#!/bin/bash

# InfoDigest 服务器停止脚本

echo "=== 停止 InfoDigest 服务器 ==="
echo ""

# 查找并停止Node进程
PIDS=$(lsof -ti:3000 2>/dev/null || true)

if [ -z "$PIDS" ]; then
    echo "✓ 服务器未运行"
else
    echo "🛑 停止服务器..."
    kill $PIDS 2>/dev/null || true
    sleep 2

    # 强制停止
    if lsof -ti:3000 > /dev/null 2>&1; then
        kill -9 $PIDS 2>/dev/null || true
    fi

    echo "✓ 服务器已停止"
fi
