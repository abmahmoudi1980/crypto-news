#!/bin/bash
# Quick deployment script with database support

echo "=========================================="
echo "Crypto News Bot - Deploy with Database"
echo "=========================================="
echo ""

# Stop any running containers
echo "1. Stopping existing containers..."
docker compose down

# Create output directory if it doesn't exist
echo "2. Creating output directory..."
mkdir -p output

# Rebuild with no cache
echo "3. Rebuilding Docker image..."
docker compose build --no-cache

# Test database locally (optional)
if command -v ruby &> /dev/null; then
    echo ""
    echo "4. Testing database functionality..."
    ruby test_database.rb
else
    echo ""
    echo "4. Skipping local test (Ruby not found in PATH)"
fi

echo ""
echo "=========================================="
echo "✓ Deployment Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Run once: docker compose up"
echo "  2. Run continuously: docker compose up -d"
echo "  3. Check logs: docker compose logs -f"
echo "  4. View stats: ruby db_manager.rb stats"
echo ""
echo "The database will prevent duplicate news automatically!"
