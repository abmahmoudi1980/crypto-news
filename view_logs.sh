#!/bin/bash
# Quick log viewer for Crypto News Bot timer runs

SERVICE="crypto-news-bot.service"
TIMER="crypto-news-bot.timer"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "╔════════════════════════════════════════════════════════════╗"
echo "║      Crypto News Bot - Timer Log Viewer                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if services exist
if ! systemctl list-unit-files | grep -q "$TIMER"; then
    echo -e "${RED}✗ Timer not installed${NC}"
    echo "Install with: sudo cp crypto-news-bot.timer /etc/systemd/system/"
    exit 1
fi

# Timer Status
echo -e "${BLUE}📊 Timer Status:${NC}"
if systemctl is-active --quiet "$TIMER"; then
    echo -e "  ${GREEN}✓ Active${NC}"
else
    echo -e "  ${RED}✗ Inactive${NC}"
fi
echo ""

# Schedule
echo -e "${BLUE}⏰ Next Run:${NC}"
systemctl list-timers "$TIMER" --no-pager | tail -n +2 | head -n 1
echo ""

# Last trigger
echo -e "${BLUE}🕐 Last Run:${NC}"
LAST_TRIGGER=$(systemctl show "$TIMER" -p LastTriggerUSec --value)
if [ "$LAST_TRIGGER" != "0" ]; then
    echo "  $(date -d @$((LAST_TRIGGER / 1000000)) '+%Y-%m-%d %H:%M:%S')"
else
    echo "  Never"
fi
echo ""

# Statistics
echo -e "${BLUE}📈 Statistics (Last 24 Hours):${NC}"

# Count runs
RUNS=$(sudo journalctl -u "$SERVICE" --since "24 hours ago" 2>/dev/null | grep -c "Bot execution completed" || echo "0")
echo "  Runs completed: $RUNS"

# Count errors
ERRORS=$(sudo journalctl -u "$SERVICE" --since "24 hours ago" -p err 2>/dev/null | wc -l)
if [ "$ERRORS" -eq 0 ]; then
    echo -e "  Errors: ${GREEN}$ERRORS${NC}"
else
    echo -e "  Errors: ${RED}$ERRORS${NC}"
fi

# Count duplicates
DUPLICATES=$(sudo journalctl -u "$SERVICE" --since "24 hours ago" 2>/dev/null | grep -c "duplicate" || echo "0")
echo "  Duplicates filtered: $DUPLICATES"

# Count sent messages
SENT=$(sudo journalctl -u "$SERVICE" --since "24 hours ago" 2>/dev/null | grep -oP "Sent \K\d+" | awk '{s+=$1} END {print s}' || echo "0")
echo "  Messages sent: $SENT"

echo ""

# Recent logs
echo -e "${BLUE}📝 Recent Logs (Last 10 Lines):${NC}"
echo "─────────────────────────────────────────────────────────────"
sudo journalctl -u "$SERVICE" -n 10 --no-pager 2>/dev/null || echo "No logs available (use sudo)"
echo "─────────────────────────────────────────────────────────────"
echo ""

# Quick commands
echo -e "${YELLOW}💡 Quick Commands:${NC}"
echo "  View all logs:        sudo journalctl -u $SERVICE"
echo "  Follow logs:          sudo journalctl -u $SERVICE -f"
echo "  Last hour:            sudo journalctl -u $SERVICE --since '1 hour ago'"
echo "  Today only:           sudo journalctl -u $SERVICE --since today"
echo "  Errors only:          sudo journalctl -u $SERVICE -p err"
echo "  Export logs:          sudo journalctl -u $SERVICE > logs.txt"
echo ""
echo "  Timer status:         systemctl status $TIMER"
echo "  Manually trigger:     sudo systemctl start $SERVICE"
echo ""
