#!/bin/bash

# InfoDigest Xcode Project Setup Automation Script

echo "🔧 InfoDigest Xcode项目自动配置"
echo "================================"
echo ""

PROJECT_PATH="/Users/huiminzhang/Bspace/project/1_iphone_app/InfoDigest/InfoDigest.xcodeproj"

echo "📋 接下来需要在Xcode中完成的步骤："
echo ""
echo "【步骤1】添加文件到Xcode项目"
echo "1. 打开Xcode中的项目（应该已经打开）"
echo "2. 在左侧项目导航器中，右键点击 'InfoDigest' 文件夹（蓝色图标）"
echo "3. 选择 'Add Files to InfoDigest...'"
echo "4. 导航到: /Users/huiminzhang/Bspace/project/1_iphone_app/InfoDigest/InfoDigest/"
echo "5. 选择所有文件夹: Models, Views, ViewModels, Services"
echo "6. 确保勾选:"
echo "   ☑ 'Copy items if needed'"
echo "   ☑ 'Create groups'"
echo "   ☑ 'InfoDigest' target"
echo "7. 点击 'Add'"
echo ""
echo "【步骤2】配置推送通知能力"
echo "1. 在Xcode中选择项目文件（最上面的蓝色图标）"
echo "2. 选择 'Signing & Capabilities' 标签"
echo "3. 点击 '+ Capability' 按钮"
echo "4. 搜索并添加 'Push Notifications'"
echo "5. 再次点击 '+ Capability'，添加 'Background Modes'"
echo "6. 在 Background Modes 中勾选:"
echo "   ☑ 'Background processing'"
echo "   ☑ 'Remote notifications'"
echo ""
echo "【步骤3】验证和运行"
echo "1. 确保选择了模拟器或真机"
echo "2. 点击 Run 按钮 (▶️) 或按 ⌘R"
echo "3. 等待构建完成"
echo ""
echo "✅ 准备好后按回车，我会帮你验证服务器状态..."
read

# 服务器配置验证
echo ""
echo "🔍 验证服务器配置..."
cd /Users/huiminzhang/Bspace/project/1_iphone_app/server

# 检查环境变量
if [ -f .env ]; then
    echo "✅ .env 文件存在"

    # 检查关键配置
    if grep -q "NEWS_API_KEY=cc9e5f521cc64efa8f84079b7a4b6c9d" .env; then
        echo "✅ NewsAPI密钥已配置"
    fi

    if grep -q "DEEPSEEK_API_KEY=sk-7b132ad9641e45a088beeb8b6520a0fb" .env; then
        echo "✅ DeepSeek API密钥已配置"
    fi

    if grep -q "DB_USER=huiminzhang" .env; then
        echo "✅ 数据库用户已配置"
    fi
else
    echo "❌ .env 文件不存在"
fi

# 检查数据库
echo ""
echo "🗄️  检查数据库..."
if psql -h localhost -U huiminzhang -d infodigest -c "SELECT 1" > /dev/null 2>&1; then
    echo "✅ 数据库连接正常"

    # 检查表
    TABLES=$(psql -h localhost -U huiminzhang -d infodigest -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'" 2>/dev/null)
    echo "✅ 数据库已初始化 ($TABLES 个表)"
else
    echo "❌ 数据库连接失败"
fi

# 检查依赖
echo ""
echo "📦 检查依赖..."
if [ -d node_modules ]; then
    echo "✅ npm依赖已安装"

    # 统计包数量
    PACKAGES=$(ls node_modules | wc -l | tr -d ' ')
    echo "   已安装 $PACKAGES 个包"
else
    echo "⚠️  npm依赖未安装，运行 'npm install'"
fi

echo ""
echo "🎉 服务器配置检查完成！"
echo ""
echo "📝 下一步操作建议："
echo "1. 在Xcode中完成上述3个步骤"
echo "2. 运行iOS应用"
echo "3. 然后我们进行端到端测试"
echo ""
echo "准备好后告诉我：'Xcode配置完成'"
echo ""

# 询问是否要启动服务器
read -p "是否现在启动服务器？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 启动开发服务器..."
    npm run dev
fi
