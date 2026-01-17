#!/bin/bash

# InfoDigest Deployment Script

set -e

echo "🚀 InfoDigest Deployment Script"
echo "================================"

# Load environment variables
if [ -f .env ]; then
    echo "✅ Loading .env file"
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "⚠️  No .env file found, using defaults"
fi

# Check required environment variables
check_env_var() {
    if [ -z "${!1}" ]; then
        echo "❌ Missing required environment variable: $1"
        exit 1
    fi
}

echo ""
echo "🔍 Checking configuration..."

# Required variables
check_env_var "DB_HOST"
check_env_var "DB_NAME"
check_env_var "DB_USER"
check_env_var "DB_PASSWORD"

echo "✅ Configuration OK"

# Install dependencies
if [ ! -d "node_modules" ]; then
    echo ""
    echo "📦 Installing dependencies..."
    npm install
fi

# Run database migrations
echo ""
echo "🗄️  Running database migrations..."
npm run migrate

# Build for production (if needed)
if [ "$NODE_ENV" = "production" ]; then
    echo ""
    echo "🔨 Building for production..."
    # Add build steps here if needed
fi

echo ""
echo "✅ Deployment complete!"
echo ""
echo "To start the server:"
echo "  npm start"
echo ""
echo "To start in development mode:"
echo "  npm run dev"
