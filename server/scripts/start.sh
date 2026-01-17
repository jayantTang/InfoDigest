#!/bin/bash

# InfoDigest Server Quick Start Script

set -e

echo "🚀 InfoDigest Server 快速启动"
echo ""

# 检查Node.js
if ! command -v node &> /dev/null; then
    echo "❌ 未找到Node.js，请先安装Node.js 18+"
    exit 1
fi

echo "✅ Node.js版本: $(node --version)"

# 检查npm
if ! command -v npm &> /dev/null; then
    echo "❌ 未找到npm"
    exit 1
fi

# 进入服务器目录
cd "$(dirname "$0")/.."

# 检查.env文件
if [ ! -f .env ]; then
    echo ""
    echo "⚙️  未找到.env文件，从模板创建..."
    cp .env.example .env
    echo "✅ 已创建.env文件"
    echo ""
    echo "⚠️  请编辑.env文件并填入必要的配置："
    echo "   - 数据库配置"
    echo "   - API密钥 (NEWS_API_KEY, OPENAI_API_KEY)"
    echo "   - APNs配置"
    echo ""
    read -p "按回车继续..."
fi

# 安装依赖
if [ ! -d node_modules ]; then
    echo ""
    echo "📦 安装依赖..."
    npm install
    echo "✅ 依赖安装完成"
fi

# 检查PostgreSQL
echo ""
echo "🔍 检查PostgreSQL..."
if psql -h localhost -U postgres -c "SELECT version();" &> /dev/null; then
    echo "✅ PostgreSQL已运行"
else
    echo "⚠️  PostgreSQL未运行或未配置"
    echo "   请先安装并启动PostgreSQL"
fi

# 初始化数据库
echo ""
read -p "是否初始化数据库？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    npm run migrate
fi

# 启动服务器
echo ""
echo "🎯 启动服务器..."
echo ""
npm run dev
