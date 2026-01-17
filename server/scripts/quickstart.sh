#!/bin/bash

# InfoDigest Quick Start Script
# This script sets up and starts the development server

set -e

echo "🎯 InfoDigest Quick Start"
echo "========================="
echo ""

# Step 1: Check prerequisites
echo "📋 Checking prerequisites..."

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed"
    echo "   Please install Node.js 18+ from https://nodejs.org/"
    exit 1
fi
echo "✅ Node.js $(node --version)"

# Check npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed"
    exit 1
fi
echo "✅ npm $(npm --version)"

# Check PostgreSQL
if command -v psql &> /dev/null; then
    echo "✅ PostgreSQL is installed"
    PG_INSTALLED=true
else
    echo "⚠️  PostgreSQL is not installed"
    echo "   You can install it or use Docker"
    PG_INSTALLED=false
fi

echo ""

# Step 2: Setup environment
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env

    echo ""
    echo "⚠️  IMPORTANT: Please edit .env and configure:"
    echo "   - DB_PASSWORD (your PostgreSQL password)"
    echo "   - NEWS_API_KEY (get from https://newsapi.org)"
    echo "   - DEEPSEEK_API_KEY (already configured)"
    echo "   - APNS_KEY_ID, APNS_TEAM_ID (for push notifications)"
    echo ""

    # Ask if user wants to edit now
    read -p "Open .env in editor now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ${EDITOR:-nano} .env
    fi
else
    echo "✅ .env file exists"
fi

echo ""

# Step 3: Install dependencies
if [ ! -d node_modules ]; then
    echo "📦 Installing dependencies..."
    npm install
    echo "✅ Dependencies installed"
else
    echo "✅ Dependencies already installed"
fi

echo ""

# Step 4: Setup database
if [ "$PG_INSTALLED" = true ]; then
    echo "🗄️  Checking PostgreSQL..."

    # Check if database exists
    if psql -h "$DB_HOST" -U "$DB_USER" -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
        echo "✅ Database '$DB_NAME' exists"
    else
        echo "📝 Creating database '$DB_NAME'..."
        psql -h "$DB_HOST" -U "$DB_USER" -c "CREATE DATABASE $DB_NAME;"
        echo "✅ Database created"
    fi

    echo ""
    echo "🔄 Running database migrations..."
    npm run migrate
    echo "✅ Database ready"
else
    echo "⚠️  Skipping database setup (PostgreSQL not found)"
    echo "   Use Docker: docker-compose up -d postgres redis"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Starting development server..."
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Start the server
npm run dev
