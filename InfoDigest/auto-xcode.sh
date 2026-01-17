#!/bin/bash

# 自动化 Xcode 首次配置和构建

echo "=== InfoDigest 自动化构建工具 ==="
echo ""
echo "正在打开 Xcode 并自动配置..."
echo ""

PROJECT_PATH="/Users/huiminzhang/Bspace/project/1_iphone_app/InfoDigest/InfoDigest.xcodeproj"

# 使用 AppleScript 自动化 Xcode
osascript <<EOF
tell application "Xcode"
    activate
    open project file "$PROJECT_PATH"
end tell

delay 3

tell application "System Events"
    tell process "Xcode"
        -- 等待项目加载
        delay 2

        -- 点击项目导航器中的项目
        try
            click menu bar item 1 of menu bar 1
            delay 1

            -- 选择项目设置
            keystroke "," using command down
            delay 2

            -- 点击 Signing & Capabilities 标签
            try
                click button "Signing & Capabilities" of sheet 1 of window 1
            on error
                -- 可能不在 sheet 中
                try
                    click button "Signing & Capabilities" of toolbar 1 of window 1
                on error
                    log "Could not find Signing & Capabilities"
                end try
            end try

            delay 1

            -- 点击 Team 下拉菜单
            try
                click pop up button "Team:" of window 1
                delay 1

                -- 选择第一个可用的团队（个人团队）
                try
                    click menu item 1 of menu 1 of pop up button "Team:" of window 1
                    delay 1
                on error errMsg
                    log "Could not select team: " & errMsg
                end try
            on error errMsg
                log "Team selection error: " & errMsg
            end try

        on error errMsg
            log "Configuration error: " & errMsg
        end try
    end tell
end tell

return "Xcode opened and configured"
EOF

echo ""
echo "✓ Xcode 已打开并尝试配置"
echo ""
echo "如果看到需要登录 Apple ID 的提示："
echo "  1. 登录你的 Apple ID"
echo "  2. 选择个人团队（Personal Team）"
echo "  3. 等待配置完成"
echo ""
echo "配置完成后，按回车继续构建..."
read

# 现在构建
echo ""
echo "开始构建..."
xcodebuild -project InfoDigest.xcodeproj \
  -scheme InfoDigest \
  -destination 'id=00008120-00012D1A3C80201E' \
  -allowProvisioningUpdates \
  -configuration Debug \
  build 2>&1 | tail -50

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ 构建成功！"
    echo "应用应该已自动安装到你的 iPhone"
else
    echo ""
    echo "构建失败，请在 Xcode 中查看错误"
fi
