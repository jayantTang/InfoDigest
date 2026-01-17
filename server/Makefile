# InfoDigest Makefile
# Convenient shortcuts for common tasks

.PHONY: help install dev start test lint docker-up docker-down docker-logs db-migrate db-reset clean deploy

# Default target
help:
	@echo "InfoDigest Server - Available Commands:"
	@echo ""
	@echo "  make install       - Install dependencies"
	@echo "  make dev           - Start development server"
	@echo "  make start         - Start production server"
	@echo "  make test          - Run tests"
	@echo "  make lint          - Run linter"
	@echo "  make docker-up     - Start Docker services"
	@echo "  make docker-down   - Stop Docker services"
	@echo "  make docker-logs   - View Docker logs"
	@echo "  make db-migrate    - Run database migrations"
	@echo "  make db-reset      - Reset database"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make deploy        - Deploy to production"
	@echo ""

# Install dependencies
install:
	npm install

# Development server
dev:
	npm run dev

# Production server
start:
	npm start

# Run tests
test:
	npm test

# Run tests in watch mode
test-watch:
	npm run test:watch

# Lint code
lint:
	npm run lint

# Fix linting issues
lint-fix:
	npm run lint:fix

# Docker commands
docker-up:
	docker-compose up -d

docker-down:
	docker-compose down

docker-logs:
	docker-compose logs -f

# Database
db-migrate:
	npm run migrate

db-reset:
	npm run db:reset

# Clean
clean:
	rm -rf node_modules
	rm -rf logs/*.log
	rm -rf .nyc_output
	rm -rf coverage

# Deploy
deploy:
	npm run deploy
