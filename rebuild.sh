#!/bin/bash
# rebuild.sh - Script to rebuild Docker image and test

echo "🧹 Cleaning up old containers and images..."
docker compose down
docker rmi crypto-news-bot:latest 2>/dev/null || true

echo ""
echo "🔨 Building Docker image..."
docker compose build --no-cache

echo ""
echo "✅ Build complete!"
echo ""
echo "To run the container, use: docker compose up"
echo "To run in detached mode, use: docker compose up -d"
