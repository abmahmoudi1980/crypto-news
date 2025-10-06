#!/bin/bash
# Analyze timer execution logs

SERVICE="crypto-news-bot.service"

# Parse time period from argument (default: 7 days)
PERIOD="${1:-7 days}"

echo "Crypto News Bot - Log Analysis"
echo "Period: Last $PERIOD"
echo "========================================"
echo ""

# Check if journalctl is available
if ! command -v journalctl &> /dev/null; then
    echo "Error: journalctl not found. This script requires systemd."
    exit 1
fi

# Get logs for the period
LOGS=$(sudo journalctl -u "$SERVICE" --since "$PERIOD ago" 2>/dev/null)

if [ -z "$LOGS" ]; then
    echo "No logs found for the specified period."
    exit 0
fi

# Count total runs
TOTAL_RUNS=$(echo "$LOGS" | grep -c "Bot execution completed")
echo "Total Runs: $TOTAL_RUNS"

# Count successful Telegram sends
TELEGRAM_SUCCESS=$(echo "$LOGS" | grep -c "messages to Telegram")
echo "Telegram Sends: $TELEGRAM_SUCCESS"

# Count new vs duplicate news
NEW_NEWS=$(echo "$LOGS" | grep -oP "Filtered results: \K\d+" | awk '{s+=$1} END {print s+0}')
DUPLICATES=$(echo "$LOGS" | grep -oP "Skipping duplicate news" | wc -l)
echo "New News: $NEW_NEWS"
echo "Duplicates: $DUPLICATES"

# Count errors
ERRORS=$(sudo journalctl -u "$SERVICE" --since "$PERIOD ago" -p err 2>/dev/null | wc -l)
echo "Errors: $ERRORS"

echo ""
echo "========================================"
echo "Detailed Breakdown:"
echo "========================================"

# Show each run with timestamp
echo ""
echo "Run History:"
echo "$LOGS" | grep "Bot execution completed" | while read -r line; do
    TIMESTAMP=$(echo "$line" | awk '{print $1, $2, $3}')
    echo "  ✓ $TIMESTAMP"
done

# Show errors if any
if [ "$ERRORS" -gt 0 ]; then
    echo ""
    echo "Recent Errors:"
    sudo journalctl -u "$SERVICE" --since "$PERIOD ago" -p err -n 5 --no-pager 2>/dev/null
fi

# Database stats (if available)
echo ""
echo "========================================"
echo "Current Database Stats:"
echo "========================================"
if [ -f "db_manager.rb" ]; then
    ruby db_manager.rb stats 2>/dev/null || echo "(Database stats not available)"
else
    echo "(db_manager.rb not found)"
fi

echo ""
echo "========================================"
echo "Analysis complete."
echo ""
echo "To view full logs: sudo journalctl -u $SERVICE --since '$PERIOD ago'"
