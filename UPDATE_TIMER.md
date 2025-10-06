# Update Timer Configuration

The timer has been updated to run **every 5 minutes** instead of hourly.

## To Apply the Changes

If you already have the timer installed on your server:

```bash
# 1. Copy the updated timer file
sudo cp crypto-news-bot.timer /etc/systemd/system/

# 2. Reload systemd to recognize changes
sudo systemctl daemon-reload

# 3. Restart the timer
sudo systemctl restart crypto-news-bot.timer

# 4. Verify the new schedule
systemctl list-timers crypto-news-bot.timer
```

You should see the timer scheduled to run every 5 minutes.

## Fresh Installation

If this is a new installation:

```bash
# 1. Copy both service and timer files
sudo cp crypto-news-bot.service /etc/systemd/system/
sudo cp crypto-news-bot.timer /etc/systemd/system/

# 2. Reload systemd
sudo systemctl daemon-reload

# 3. Enable the timer (start on boot)
sudo systemctl enable crypto-news-bot.timer

# 4. Start the timer
sudo systemctl start crypto-news-bot.timer

# 5. Check status
systemctl status crypto-news-bot.timer
systemctl list-timers crypto-news-bot.timer
```

## Verify It's Working

```bash
# Check timer status
systemctl status crypto-news-bot.timer

# See next 5 scheduled runs
systemctl list-timers crypto-news-bot.timer

# Follow logs to see when it runs
sudo journalctl -u crypto-news-bot.service -f
```

## Change Schedule

To modify the interval, edit the `OnCalendar` line in the timer file:

```ini
# Every 5 minutes (current)
OnCalendar=*:0/5

# Every 10 minutes
OnCalendar=*:0/10

# Every 15 minutes
OnCalendar=*:0/15

# Every 30 minutes
OnCalendar=*:0/30

# Every hour
OnCalendar=hourly

# Every 2 hours
OnCalendar=0/2:00

# Every day at 9 AM
OnCalendar=*-*-* 09:00:00

# Twice daily (9 AM and 6 PM)
OnCalendar=*-*-* 09:00:00
OnCalendar=*-*-* 18:00:00
```

After editing, always run:

```bash
sudo cp crypto-news-bot.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl restart crypto-news-bot.timer
```

## Important Note

Running every 5 minutes means:

- ⚠️ Higher API usage (OpenRouter costs)
- ⚠️ More Telegram API calls
- ✅ More frequent news updates
- ✅ Database will catch duplicates automatically

Consider your API rate limits and costs before running frequently.

## Monitor Activity

```bash
# See how many times it ran today
sudo journalctl -u crypto-news-bot.service --since today | grep -c "Bot execution completed"

# View logs dashboard
sudo ./view_logs.sh

# Analyze recent activity
sudo ./analyze_logs.sh "1 hour"
```

## Recommended Schedules

- **Every 5 min** - Testing or very active monitoring
- **Every 15 min** - Frequent updates
- **Every 30 min** - Moderate updates
- **Every hour** - Standard news monitoring (recommended)
- **Every 4 hours** - Conservative API usage
- **Daily** - Summary reports

Current setting: **Every 5 minutes**
