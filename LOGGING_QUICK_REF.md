# Timer Logging - Quick Reference

## 🚀 Quick Start

After installing the timer, all runs are **automatically logged** to systemd journal.

## 📋 Essential Commands

### View Logs

```bash
# Last 50 log lines
sudo journalctl -u crypto-news-bot.service -n 50

# Follow logs in real-time (like tail -f)
sudo journalctl -u crypto-news-bot.service -f

# Today's logs
sudo journalctl -u crypto-news-bot.service --since today

# Last hour
sudo journalctl -u crypto-news-bot.service --since "1 hour ago"
```

### Check Timer Status

```bash
# Timer status and next run time
systemctl status crypto-news-bot.timer

# List when timer will run next
systemctl list-timers crypto-news-bot.timer

# See timer history
sudo journalctl -u crypto-news-bot.timer
```

### Search Logs

```bash
# Find errors only
sudo journalctl -u crypto-news-bot.service -p err

# Search for specific text
sudo journalctl -u crypto-news-bot.service | grep "duplicate"

# Count successful runs today
sudo journalctl -u crypto-news-bot.service --since today | grep -c "Bot execution completed"
```

## 🛠️ Helper Scripts

We've created helper scripts for you:

### View Logs Dashboard

```bash
chmod +x view_logs.sh
sudo ./view_logs.sh
```

Shows:

- Timer status
- Next run time
- Last 24h statistics
- Recent log entries

### Analyze Logs

```bash
chmod +x analyze_logs.sh

# Last 7 days (default)
sudo ./analyze_logs.sh

# Last 30 days
sudo ./analyze_logs.sh "30 days"

# Last 24 hours
sudo ./analyze_logs.sh "24 hours"
```

Shows:

- Total runs
- Success/error counts
- New vs duplicate news
- Run history

## 📊 What Gets Logged

Every timer run logs:

- ✅ Start time
- ✅ News fetched from sources
- ✅ AI analysis results
- ✅ Duplicate detection
- ✅ New messages count
- ✅ Telegram send results
- ✅ Database statistics
- ✅ Completion time
- ✅ Any errors or warnings

## 📁 Log Location

Logs are stored in systemd journal:

- Path: `/var/log/journal/` (binary format)
- View with: `journalctl` command
- Persists across reboots
- Auto-rotated by systemd

## 💡 Common Use Cases

### See last run

```bash
sudo journalctl -u crypto-news-bot.service -n 100 | grep "Bot execution completed" | tail -n 1
```

### Check if it ran today

```bash
sudo journalctl -u crypto-news-bot.service --since today | grep -q "Bot execution completed" && echo "Yes" || echo "No"
```

### Count how many news sent today

```bash
sudo journalctl -u crypto-news-bot.service --since today | grep "Sent.*messages to Telegram"
```

### Export last 7 days to file

```bash
sudo journalctl -u crypto-news-bot.service --since "7 days ago" > last-week-logs.txt
```

### Check for errors in last 24h

```bash
sudo journalctl -u crypto-news-bot.service --since "24 hours ago" -p err
```

## 🔔 Set Up Email Alerts (Optional)

1. Install mail utility:

```bash
sudo apt install mailutils
```

2. Create notification service:

```bash
sudo nano /etc/systemd/system/crypto-news-bot-notify@.service
```

Add:

```ini
[Unit]
Description=Crypto News Bot Failure Notification

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'journalctl -u crypto-news-bot.service -n 50 | mail -s "Crypto Bot Failed" your@email.com'
```

3. Update main service to call on failure:

```bash
sudo nano /etc/systemd/system/crypto-news-bot.service
```

Add under `[Service]`:

```ini
OnFailure=crypto-news-bot-notify@%n.service
```

4. Reload and restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart crypto-news-bot.timer
```

## 📈 Monitor Performance

Create a cron job to log statistics:

```bash
# Edit crontab
crontab -e

# Add line (runs daily at 23:00)
0 23 * * * cd /opt/crypto-news && sudo ./analyze_logs.sh "24 hours" >> /var/log/crypto-bot-daily-report.txt
```

## 🔧 Troubleshooting

### "Permission denied" when viewing logs

**Solution:** Use `sudo` or add your user to `systemd-journal` group:

```bash
sudo usermod -aG systemd-journal $USER
# Log out and back in
```

### No logs appearing

**Check:**

1. Timer is running: `systemctl status crypto-news-bot.timer`
2. Service exists: `systemctl list-unit-files | grep crypto-news-bot`
3. Journal is active: `systemctl status systemd-journald`

**Test manually:**

```bash
sudo systemctl start crypto-news-bot.service
sudo journalctl -u crypto-news-bot.service -f
```

### Logs too old

**Increase retention:**

```bash
sudo nano /etc/systemd/journald.conf
```

Set:

```ini
[Journal]
MaxRetentionSec=90d
SystemMaxUse=2G
```

Restart:

```bash
sudo systemctl restart systemd-journald
```

## 📚 More Information

For detailed logging guide, see: `SYSTEMD_LOGGING.md`

## Summary

✅ **Logs are automatic** - No setup needed
✅ **Use journalctl** - View with `sudo journalctl -u crypto-news-bot.service`
✅ **Use helper scripts** - `./view_logs.sh` and `./analyze_logs.sh`
✅ **Logs persist** - Survives reboots
✅ **Auto-rotated** - Managed by systemd

**Most common command:**

```bash
sudo journalctl -u crypto-news-bot.service -f
```

This follows logs in real-time! 🎉
