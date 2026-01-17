#!/bin/bash

# InfoDigest Docker Quick Start
# Starts all services using Docker Compose

set -e

echo "🐳 InfoDigest Docker Setup"
echo "==========================="
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    echo "   Please install Docker from https://docker.com"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed"
    exit 1
fi

echo "✅ Docker is installed"
echo ""

# Setup environment
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env

    echo ""
    echo "⚠️  Please edit .env and configure your API keys"
    read -p "Press Enter to continue..."
fi

# Create certificates directory
mkdir -p certs

echo ""
echo "🚀 Starting services..."
echo ""

# Start services
docker-compose up -d

echo ""
echo "✅ Services started!"
echo ""
echo "Services:"
echo "  - API Server: http://localhost:3000"
echo "  - PostgreSQL: localhost:5432"
echo "  - Redis: localhost:6379"
echo ""
echo "Commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Stop services: docker-compose down"
echo "  - Restart: docker-compose restart"
echo ""
echo "To run database migrations:"
echo "  docker-compose exec app npm run migrate"
echo ""

# Show logs
docker-compose logs -f app
