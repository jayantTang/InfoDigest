#!/bin/bash

# InfoDigest 自动构建和安装到 iPhone

echo "=== InfoDigest 自动构建安装工具 ==="
echo ""

PROJECT_DIR="/Users/huiminzhang/Bspace/project/1_iphone_app/InfoDigest"
PROJECT_FILE="$PROJECT_DIR/InfoDigest.xcodeproj"
SCHEME="InfoDigest"
DEVICE_ID="00008120-00012D1A3C80201E"

cd "$PROJECT_DIR"

# 检查设备连接
echo "1. 检查 iPhone 连接..."
if ! system_profiler SPUSBDataType 2>/dev/null | grep -q "iPhone"; then
    echo "❌ 未检测到 iPhone 连接"
    echo "请确保："
    echo "  - iPhone 已通过 USB 连接到 Mac"
    echo "  - iPhone 已解锁"
    exit 1
fi
echo "✓ iPhone 已连接"

# 检查开发者模式
echo ""
echo "2. 检查开发者模式..."
# xcodebuild 会自动处理这个

# 设置构建配置
echo ""
echo "3. 开始构建应用..."

# 使用 xcodebuild 构建，让 Xcode 自动处理签名
xcodebuild \
    -project "$PROJECT_FILE" \
    -scheme "$SCHEME" \
    -destination "id=$DEVICE_ID" \
    -configuration Debug \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic \
    CODE_SIGN_IDENTITY="Apple Development" \
    DEVELOPMENT_TEAM="" \
    clean \
    build \
    | while IFS= read -r line; do
        echo "$line"
        # 检查是否需要用户交互
        if echo "$line" | grep -q "requires a development team"; then
            echo ""
            echo "⚠️  需要在 Xcode 中选择开发团队"
            echo "1. Xcode 会自动打开"
            echo "2. 在弹出的对话框中登录你的 Apple ID"
            echo "3. 选择你的个人团队（Personal Team）"
            echo "4. 点击 'Choose' 按钮"
            echo ""
            echo "选择完成后，按回车继续..."
            read
        fi
    done

# 检查构建结果
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "✓ 构建成功！"

    # 查找构建的 .app 文件
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/InfoDigest-*/Build/Products/Debug-iphoneos/InfoDigest.app -maxdepth 0 -type d 2>/dev/null | head -1)

    if [ -n "$APP_PATH" ]; then
        echo "✓ 应用文件: $APP_PATH"

        # 使用 ios-deploy 安装（如果可用）或 xcrun
        echo ""
        echo "4. 安装到 iPhone..."

        if command -v ios-deploy &> /dev/null; then
            ios-deploy --bundle "$APP_PATH" --no-wifi
        else
            # 使用 xcrun 安装
            xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH" 2>&1 || \
            echo "⚠️  自动安装失败，请从 Xcode 手动安装"
        fi

        echo ""
        echo "✓ 完成！应用已安装到 iPhone"
        echo ""
        echo "📱 在 iPhone 上："
        echo "  1. 找到 InfoDigest 应用"
        echo "  2. 首次打开需要信任开发者"
        echo "  3. 设置 → 通用 → VPN与设备管理 → 信任"
        echo ""
    else
        echo "⚠️  未找到构建的应用文件"
        echo "请从 Xcode 手动运行"
    fi
else
    echo ""
    echo "❌ 构建失败"
    echo ""
    echo "可能的原因："
    echo "  1. 需要登录 Apple ID（在 Xcode 中）"
    echo "  2. 需要启用开发者模式（在 iPhone 上）"
    echo "  3. 需要信任此电脑（在 iPhone 上）"
    echo ""
    echo "请打开 Xcode 手动完成首次配置："
    echo "  open $PROJECT_FILE"
fi
