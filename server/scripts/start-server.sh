#!/bin/bash

# InfoDigest 服务器启动脚本

SERVER_DIR="/Users/huiminzhang/Bspace/project/1_iphone_app/server"

echo "=== 启动 InfoDigest 服务器 ==="
echo ""

# 检查Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js未安装"
    exit 1
fi

# 进入服务器目录
cd "$SERVER_DIR"

# 检查依赖
if [ ! -d "node_modules" ]; then
    echo "📦 安装依赖..."
    npm install
fi

# 检查数据库
echo "📊 检查数据库连接..."
if ! psql -h localhost -U huiminzhang -d infodigest -c "SELECT 1" > /dev/null 2>&1; then
    echo "⚠️  数据库未初始化，正在初始化..."
    npm run migrate
fi

# 启动服务器
echo "🚀 启动服务器..."
npm run dev
