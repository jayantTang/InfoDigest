#!/bin/bash

# InfoDigest iOS自动构建脚本
# 用途：构建iOS应用并安装到iPhone

set -e  # 遇到错误立即退出

PROJECT="/Users/huiminzhang/Bspace/project/1_iphone_app/InfoDigest"
DEVICE="00008120-00012D1A3C80201E"

echo "=== InfoDigest iOS 自动构建 ==="
echo ""

# 检查服务器
echo "1. 检查服务器..."
if ! curl -s http://localhost:3000/health > /dev/null; then
    echo "⚠️  服务器未运行，正在启动..."
    cd /Users/huiminzhang/Bspace/project/1_iphone_app/server
    npm run dev &
    sleep 3
    cd "$PROJECT"
fi
echo "✓ 服务器运行中"

# 构建
echo ""
echo "2. 构建应用..."
cd "$PROJECT"
xcodebuild \
    -project InfoDigest.xcodeproj \
    -scheme InfoDigest \
    -destination "id=$DEVICE" \
    -configuration Debug \
    -derivedDataPath ./build \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=J45TT5R9C6 \
    2>&1 | tail -20

BUILD_STATUS=${PIPESTATUS[0]}

if [ $BUILD_STATUS -eq 0 ]; then
    echo ""
    echo "✓ 构建成功！"

    # 查找构建的app
    APP_PATH=$(find ./build -name "InfoDigest.app" -type d | head -1)

    if [ -n "$APP_PATH" ]; then
        echo ""
        echo "3. 安装应用到 iPhone..."
        ios-deploy --id "$DEVICE" --bundle "$APP_PATH" --no-wifi 2>&1 | tail -10

        if [ $? -eq 0 ]; then
            echo ""
            echo "✅ 应用已成功安装到 iPhone！"
            echo ""
            echo "📱 请在 iPhone 上打开 InfoDigest 应用"
        else
            echo ""
            echo "⚠️  构建成功，但安装失败"
        fi
    fi
else
    echo ""
    echo "❌ 构建失败"
fi
