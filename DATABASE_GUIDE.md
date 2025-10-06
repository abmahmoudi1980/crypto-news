# SQLite Database Integration - Quick Reference

## What Changed

Added SQLite database to prevent sending duplicate news to Telegram.

### New Files:

- `database_manager.rb` - Database operations class
- `db_manager.rb` - Command-line utility for database management

### Modified Files:

- `main.rb` - Integrated database duplicate checking
- `Gemfile` - Added sqlite3 gem
- `Dockerfile` - Added SQLite3 packages
- `docker-compose.yml` - Updated volume comment
- `.gitignore` - Added database files

## Database Schema

```sql
CREATE TABLE news (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  date TEXT,
  url TEXT NOT NULL UNIQUE,    -- Unique constraint prevents duplicates
  url_hash TEXT NOT NULL,       -- SHA256 hash for fast lookups
  source TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## How It Works

1. **Bot fetches news** from sources
2. **AI analyzes** and generates messages
3. **Database checks** each message URL
4. **Only new news** is sent to Telegram
5. **URL is stored** in database to prevent future duplicates

## Usage

### Run the Bot

```bash
# Docker
docker compose build --no-cache
docker compose up

# Or for hourly scheduling
docker compose up -d
```

### Manage Database

```bash
# View statistics
ruby db_manager.rb stats

# List recent news
ruby db_manager.rb list 20

# Clean up old entries (30 days)
ruby db_manager.rb cleanup 30

# Export to JSON
ruby db_manager.rb export backup.json

# Reset database (careful!)
ruby db_manager.rb reset
```

### Inside Docker Container

```bash
# Access running container
docker exec -it crypto-news-bot bash

# Run database commands
cd /app/output
ruby /app/db_manager.rb stats
```

## Database Location

- **Local**: `crypto_news.db` (in project root)
- **Docker**: `/app/output/crypto_news.db` (persisted via volume)

The database file is automatically created on first run.

## Duplicate Detection

The system uses URL as the unique identifier:

- URLs are normalized (lowercase, trimmed)
- SHA256 hash created for fast lookups
- Unique constraint at database level prevents duplicates
- Duplicate news is skipped and logged

## Automatic Cleanup

You can schedule automatic cleanup of old news:

```bash
# In crontab (run monthly)
0 0 1 * * cd /path/to/crypto_news && ruby db_manager.rb cleanup 30
```

Or add to the bot's main.rb if desired.

## Monitoring

```bash
# Check how many news items stored
docker exec crypto-news-bot ruby /app/db_manager.rb stats

# View recent entries
docker exec crypto-news-bot ruby /app/db_manager.rb list 10

# Export for analysis
docker exec crypto-news-bot ruby /app/db_manager.rb export /app/output/export.json
```

## Troubleshooting

### Database locked error

- Usually happens if bot is running while you access DB
- Stop the bot, then run db_manager

### Database file not found

- Will be auto-created on first run
- In Docker, check `/app/output/` directory
- Ensure volume is mounted correctly

### Reset after testing

```bash
ruby db_manager.rb reset
```

## Performance

- Indexed on `url_hash` for O(1) duplicate checks
- Indexed on `created_at` for fast recent queries
- Handles thousands of entries efficiently
