# Systemd Timer Logging Guide

## Overview

Systemd automatically logs all service and timer events to the systemd journal. This guide shows you how to view and monitor these logs.

## Quick Commands

### View Recent Logs

```bash
# View last 50 lines of service logs
sudo journalctl -u crypto-news-bot.service -n 50

# View logs from the last hour
sudo journalctl -u crypto-news-bot.service --since "1 hour ago"

# View logs from today
sudo journalctl -u crypto-news-bot.service --since today

# View logs with timestamps
sudo journalctl -u crypto-news-bot.service -o short-iso
```

### Follow Logs in Real-Time

```bash
# Watch logs as they happen (like tail -f)
sudo journalctl -u crypto-news-bot.service -f

# Follow both service and timer logs
sudo journalctl -u crypto-news-bot.service -u crypto-news-bot.timer -f
```

### View Timer Status

```bash
# Check when timer last ran and when it will run next
systemctl status crypto-news-bot.timer

# List all timer schedules
systemctl list-timers crypto-news-bot.timer

# Detailed timer info
systemctl show crypto-news-bot.timer
```

## Logging Configuration

The service file is configured with:

```ini
[Service]
StandardOutput=journal      # Send stdout to systemd journal
StandardError=journal       # Send stderr to systemd journal
SyslogIdentifier=crypto-news-bot  # Tag for easy filtering
```

This means:

- ✅ All output is automatically logged
- ✅ Logs persist across reboots (by default)
- ✅ Logs are indexed and searchable
- ✅ Rotation is handled automatically

## Viewing Logs by Time

### Last X minutes/hours/days

```bash
# Last 30 minutes
sudo journalctl -u crypto-news-bot.service --since "30 minutes ago"

# Last 2 hours
sudo journalctl -u crypto-news-bot.service --since "2 hours ago"

# Last 7 days
sudo journalctl -u crypto-news-bot.service --since "7 days ago"
```

### Specific time range

```bash
# Between specific dates
sudo journalctl -u crypto-news-bot.service \
  --since "2025-10-06 00:00:00" \
  --until "2025-10-06 23:59:59"

# Yesterday
sudo journalctl -u crypto-news-bot.service --since yesterday --until today

# This week
sudo journalctl -u crypto-news-bot.service --since "1 week ago"
```

## Viewing Timer Activation Logs

```bash
# See when timer was activated
sudo journalctl -u crypto-news-bot.timer

# Timer events with service events
sudo journalctl -u crypto-news-bot.timer -u crypto-news-bot.service
```

## Filtering Logs

### By priority level

```bash
# Errors only
sudo journalctl -u crypto-news-bot.service -p err

# Warnings and above
sudo journalctl -u crypto-news-bot.service -p warning

# Info and above
sudo journalctl -u crypto-news-bot.service -p info
```

### Search for specific text

```bash
# Search for "error" in logs
sudo journalctl -u crypto-news-bot.service | grep -i error

# Search for "duplicate"
sudo journalctl -u crypto-news-bot.service | grep -i duplicate

# Search for specific date
sudo journalctl -u crypto-news-bot.service | grep "2025-10-06"
```

## Export Logs

### Save to file

```bash
# Export all logs to a file
sudo journalctl -u crypto-news-bot.service > crypto-bot-logs.txt

# Export last 100 lines
sudo journalctl -u crypto-news-bot.service -n 100 > last-100-logs.txt

# Export today's logs
sudo journalctl -u crypto-news-bot.service --since today > today-logs.txt

# Export with JSON format for analysis
sudo journalctl -u crypto-news-bot.service -o json > logs.json
```

## Log Statistics

```bash
# Show disk usage by service
sudo journalctl --disk-usage

# Show logs size for specific service
sudo journalctl -u crypto-news-bot.service --disk-usage

# Verify logs exist
sudo journalctl -u crypto-news-bot.service --verify
```

## Advanced Monitoring

### Create a log monitoring script

Create `/usr/local/bin/crypto-bot-monitor.sh`:

```bash
#!/bin/bash
# Monitor script for crypto news bot

LOG_FILE="/var/log/crypto-news-bot-monitor.log"

echo "========================================" >> "$LOG_FILE"
echo "Monitor Check: $(date)" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# Check timer status
echo "Timer Status:" >> "$LOG_FILE"
systemctl is-active crypto-news-bot.timer >> "$LOG_FILE"

# Check when last run
echo -e "\nLast Run:" >> "$LOG_FILE"
systemctl show crypto-news-bot.timer -p LastTriggerUSec >> "$LOG_FILE"

# Check next run
echo -e "\nNext Run:" >> "$LOG_FILE"
systemctl show crypto-news-bot.timer -p NextElapseUSecRealtime >> "$LOG_FILE"

# Check for errors in last hour
echo -e "\nRecent Errors:" >> "$LOG_FILE"
journalctl -u crypto-news-bot.service --since "1 hour ago" -p err -n 10 >> "$LOG_FILE"

# Count successful runs today
RUNS=$(journalctl -u crypto-news-bot.service --since today | grep -c "Bot execution completed" || echo "0")
echo -e "\nSuccessful runs today: $RUNS" >> "$LOG_FILE"

echo "========================================" >> "$LOG_FILE"
```

Make it executable:

```bash
sudo chmod +x /usr/local/bin/crypto-bot-monitor.sh
```

Run periodically:

```bash
sudo /usr/local/bin/crypto-bot-monitor.sh
cat /var/log/crypto-news-bot-monitor.log
```

### Email notifications on failure

Create `/etc/systemd/system/crypto-news-bot-notify@.service`:

```ini
[Unit]
Description=Email notification for crypto-news-bot failure

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo "Crypto News Bot failed at $(date)" | mail -s "Crypto Bot Alert" your-email@example.com'
```

Then update the main service to call this on failure:

```ini
[Service]
OnFailure=crypto-news-bot-notify@%n.service
```

## Persistent Logging

By default, systemd journal is persistent. To ensure it stays that way:

```bash
# Check journal configuration
sudo cat /etc/systemd/journald.conf | grep Storage

# If not set to persistent, enable it
sudo sed -i 's/#Storage=auto/Storage=persistent/' /etc/systemd/journald.conf
sudo systemctl restart systemd-journald
```

## Log Rotation

Systemd handles log rotation automatically. Configure limits:

Edit `/etc/systemd/journald.conf`:

```ini
[Journal]
# Keep logs up to 1GB
SystemMaxUse=1G

# Keep logs for 30 days
MaxRetentionSec=30d

# Max size per file
SystemMaxFileSize=100M
```

Apply changes:

```bash
sudo systemctl restart systemd-journald
```

## Common Log Patterns to Look For

### Successful run

```bash
sudo journalctl -u crypto-news-bot.service | grep "Bot execution completed"
```

### Errors

```bash
sudo journalctl -u crypto-news-bot.service | grep -E "ERROR|FATAL|Failed"
```

### Duplicate detection

```bash
sudo journalctl -u crypto-news-bot.service | grep "duplicate"
```

### Telegram sends

```bash
sudo journalctl -u crypto-news-bot.service | grep "Sent.*messages to Telegram"
```

### Database stats

```bash
sudo journalctl -u crypto-news-bot.service | grep "Database Statistics"
```

## Dashboard View

Create a simple dashboard script `/usr/local/bin/crypto-bot-dashboard.sh`:

```bash
#!/bin/bash

clear
echo "╔════════════════════════════════════════════════════════╗"
echo "║         Crypto News Bot - Dashboard                   ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

echo "📊 Timer Status:"
systemctl is-active crypto-news-bot.timer && echo "  ✓ Active" || echo "  ✗ Inactive"
echo ""

echo "⏰ Schedule:"
systemctl list-timers crypto-news-bot.timer --no-pager | tail -n +2
echo ""

echo "📈 Recent Activity (last 24h):"
RUNS=$(journalctl -u crypto-news-bot.service --since "24 hours ago" | grep -c "Bot execution completed" || echo "0")
echo "  Successful runs: $RUNS"
ERRORS=$(journalctl -u crypto-news-bot.service --since "24 hours ago" -p err | wc -l)
echo "  Errors: $ERRORS"
echo ""

echo "📝 Last 5 Log Entries:"
sudo journalctl -u crypto-news-bot.service -n 5 --no-pager
echo ""

echo "💾 Database Stats:"
cd /opt/crypto-news && ruby db_manager.rb stats 2>/dev/null || echo "  (Database manager not available)"
```

Make it executable and run:

```bash
sudo chmod +x /usr/local/bin/crypto-bot-dashboard.sh
sudo /usr/local/bin/crypto-bot-dashboard.sh
```

## Quick Reference Card

```bash
# View logs
journalctl -u crypto-news-bot.service

# Follow logs
journalctl -u crypto-news-bot.service -f

# Last hour
journalctl -u crypto-news-bot.service --since "1 hour ago"

# Today only
journalctl -u crypto-news-bot.service --since today

# Timer status
systemctl status crypto-news-bot.timer

# Next run time
systemctl list-timers crypto-news-bot.timer

# Check for errors
journalctl -u crypto-news-bot.service -p err

# Export logs
journalctl -u crypto-news-bot.service > logs.txt

# Count runs
journalctl -u crypto-news-bot.service | grep -c "Bot execution completed"
```

## Troubleshooting

### No logs appearing

```bash
# Check service status
systemctl status crypto-news-bot.service

# Manually trigger service to test
sudo systemctl start crypto-news-bot.service

# Check journal is running
systemctl status systemd-journald
```

### Logs too old

```bash
# Check retention settings
journalctl --vacuum-time=30d

# Check disk usage
journalctl --disk-usage
```

### Permission denied

```bash
# Add your user to systemd-journal group
sudo usermod -aG systemd-journal $USER

# Or use sudo
sudo journalctl -u crypto-news-bot.service
```

## Summary

All timer runs are **automatically logged** to systemd journal. Use:

- `journalctl -u crypto-news-bot.service` - View logs
- `journalctl -u crypto-news-bot.service -f` - Follow logs
- `systemctl status crypto-news-bot.timer` - Check timer status
- `systemctl list-timers` - See next run time

Logs include:

- ✅ When timer activates
- ✅ Service start/stop
- ✅ All bot output
- ✅ Errors and warnings
- ✅ Database operations
- ✅ Telegram sends
