#!/bin/bash
# Quick start script for Crypto News Bot

echo "======================================"
echo "Crypto News Bot - Quick Start"
echo "======================================"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found!"
    echo ""
    echo "Creating .env from template..."
    cp .env.example .env
    echo "✓ Created .env file"
    echo ""
    echo "Please edit .env and add your API keys:"
    echo "  - OPENROUTER_API_KEY (required)"
    echo "  - TELEGRAM_BOT_TOKEN (optional)"
    echo "  - TELEGRAM_CHAT_ID (optional)"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Check if OPENROUTER_API_KEY is set
if ! grep -q "OPENROUTER_API_KEY=.\+" .env; then
    echo "⚠️  OPENROUTER_API_KEY is not configured in .env"
    echo ""
    echo "Please edit .env and add your OpenRouter API key."
    exit 1
fi

echo "✓ Configuration found"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "✗ Docker is not running"
    echo "Please start Docker and try again."
    exit 1
fi

echo "✓ Docker is running"
echo ""

# Ask user if they want to build or use existing image
echo "Choose an option:"
echo "  1) Build and run (fresh build)"
echo "  2) Run with existing image"
echo "  3) Build only"
echo ""
read -p "Enter choice [1-3]: " choice

case $choice in
    1)
        echo ""
        echo "Building Docker image..."
        docker-compose build
        echo ""
        echo "Starting bot..."
        docker-compose up
        ;;
    2)
        echo ""
        echo "Starting bot..."
        docker-compose up
        ;;
    3)
        echo ""
        echo "Building Docker image..."
        docker-compose build
        echo ""
        echo "✓ Build complete"
        echo ""
        echo "Run 'docker-compose up' to start the bot"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
