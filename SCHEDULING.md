# Crypto News Bot - Scheduling Guide

This guide explains how to run the Crypto News Bot automatically on a schedule.

## Option 1: Systemd Timer (Linux - Recommended)

### Run Every Hour (Already configured)

The `crypto-news-bot.timer` is now configured to run every hour.

#### Installation Steps:

```bash
# 1. Copy service files to systemd directory
sudo cp crypto-news-bot.service /etc/systemd/system/
sudo cp crypto-news-bot.timer /etc/systemd/system/

# 2. Update paths in the service file
sudo nano /etc/systemd/system/crypto-news-bot.service
# Change WorkingDirectory to your actual path (e.g., /home/user/crypto_news)
# Change User and Group if needed

# 3. Reload systemd to recognize new files
sudo systemctl daemon-reload

# 4. Enable the timer to start on boot
sudo systemctl enable crypto-news-bot.timer

# 5. Start the timer
sudo systemctl start crypto-news-bot.timer

# 6. Verify it's running
sudo systemctl status crypto-news-bot.timer

# 7. See when it will run next
systemctl list-timers crypto-news-bot.timer
```

#### Useful Commands:

```bash
# Check timer status
sudo systemctl status crypto-news-bot.timer

# View service logs
sudo journalctl -u crypto-news-bot.service -f

# View recent runs
sudo journalctl -u crypto-news-bot.service --since "1 hour ago"

# Stop the timer
sudo systemctl stop crypto-news-bot.timer

# Disable the timer (won't start on boot)
sudo systemctl disable crypto-news-bot.timer

# Manually trigger the service (for testing)
sudo systemctl start crypto-news-bot.service
```

### Custom Schedules

Edit the timer file and change the `OnCalendar` line:

```ini
# Every hour at the top of the hour (00:00, 01:00, 02:00, etc.)
OnCalendar=hourly

# Every 2 hours
OnCalendar=*-*-* 00/2:00:00

# Every 30 minutes
OnCalendar=*:0/30

# Every 4 hours at :15 past the hour
OnCalendar=*-*-* 00/4:15:00

# Every day at 9 AM
OnCalendar=*-*-* 09:00:00

# Every weekday at 9 AM
OnCalendar=Mon-Fri *-*-* 09:00:00

# Twice daily (9 AM and 6 PM)
OnCalendar=*-*-* 09:00:00
OnCalendar=*-*-* 18:00:00
```

After editing, reload:

```bash
sudo systemctl daemon-reload
sudo systemctl restart crypto-news-bot.timer
```

---

## Option 2: Docker Compose with Built-in Loop

Modify `docker-compose.yml` to run the bot in a continuous loop:

```yaml
services:
  crypto-news-bot:
    build: .
    container_name: crypto-news-bot
    environment:
      - OPENROUTER_API_KEY=${OPENROUTER_API_KEY}
      - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
      - TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID}
    volumes:
      - ./output:/app/output
    restart: unless-stopped
    # Run every hour (3600 seconds)
    command: sh -c "while true; do ruby main.rb && sleep 3600; done"
```

Then run:

```bash
docker compose up -d
```

To change the interval, modify the sleep time:

- `sleep 3600` = 1 hour
- `sleep 1800` = 30 minutes
- `sleep 7200` = 2 hours
- `sleep 86400` = 24 hours (daily)

---

## Option 3: Cron (Linux/macOS)

### Setup:

```bash
# Open crontab editor
crontab -e

# Add one of these lines:
```

### Cron Schedule Examples:

```bash
# Every hour at minute 0
0 * * * * cd /path/to/crypto_news && docker compose run --rm crypto-news-bot

# Every 2 hours
0 */2 * * * cd /path/to/crypto_news && docker compose run --rm crypto-news-bot

# Every day at 9 AM
0 9 * * * cd /path/to/crypto_news && docker compose run --rm crypto-news-bot

# Every 30 minutes
*/30 * * * * cd /path/to/crypto_news && docker compose run --rm crypto-news-bot

# Every weekday at 9 AM
0 9 * * 1-5 cd /path/to/crypto_news && docker compose run --rm crypto-news-bot
```

### With logging:

```bash
0 * * * * cd /path/to/crypto_news && docker compose run --rm crypto-news-bot >> /var/log/crypto-news-bot.log 2>&1
```

---

## Option 4: Windows Task Scheduler

### Using PowerShell Script:

1. Create `run-bot.ps1`:

```powershell
Set-Location "D:\apps\crypto_news"
docker compose run --rm crypto-news-bot
```

2. Open Task Scheduler
3. Create Basic Task
4. Name: "Crypto News Bot"
5. Trigger: Choose frequency (e.g., "Daily" or use "Custom" for hourly)
6. Action: Start a program
   - Program: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "D:\apps\crypto_news\run-bot.ps1"`
7. For hourly: After creating, edit the task and change trigger to repeat every 1 hour

---

## Recommendation by Platform

- **Linux Server**: Use **Systemd Timer** (Option 1) - Most reliable, built-in monitoring
- **Linux/macOS Simple**: Use **Cron** (Option 3) - Simple and widely understood
- **Docker-only**: Use **Docker Loop** (Option 2) - Self-contained, no external dependencies
- **Windows**: Use **Task Scheduler** (Option 4) - Native Windows solution

---

## Monitoring

### Check if the bot is running:

```bash
# For systemd
sudo systemctl status crypto-news-bot.timer
systemctl list-timers crypto-news-bot.timer

# For Docker
docker ps
docker logs crypto-news-bot -f

# For cron
grep CRON /var/log/syslog
```

### View output/logs:

```bash
# Check output directory
ls -lh output/

# View latest fetched news
cat output/fetched_news.json

# Docker logs
docker compose logs -f
```

---

## Troubleshooting

### Timer not running:

```bash
sudo systemctl status crypto-news-bot.timer
sudo journalctl -u crypto-news-bot.timer -n 50
```

### Service failing:

```bash
sudo journalctl -u crypto-news-bot.service -n 50
```

### Docker issues:

```bash
docker compose logs
docker compose down
docker compose build --no-cache
docker compose up
```

### Test manually:

```bash
# Systemd
sudo systemctl start crypto-news-bot.service

# Docker
docker compose run --rm crypto-news-bot

# Direct
cd /path/to/crypto_news && bundle exec ruby main.rb
```
