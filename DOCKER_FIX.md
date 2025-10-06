# Docker Gem Installation Fix

## Problem

The application was failing to load gems (`dotenv`, `httparty`, etc.) when running in Docker production mode. The error occurred because:

1. Gems were installed during `docker build` using `bundle install`
2. The container was running `ruby main.rb` directly without `bundle exec`
3. This caused Ruby to not find the gems in the bundle path

## Solution Applied

### 1. Updated Dockerfile CMD

**Changed from:**

```dockerfile
CMD ["ruby", "main.rb"]
```

**Changed to:**

```dockerfile
CMD ["bundle", "exec", "ruby", "main.rb"]
```

### 2. Improved Gemfile Copying

**Changed from:**

```dockerfile
COPY Gemfile ./
```

**Changed to:**

```dockerfile
COPY Gemfile* ./
```

This now copies both `Gemfile` and `Gemfile.lock` (if it exists), which ensures consistent gem versions.

## Why This Fix Works

- `bundle exec` runs the Ruby script in the context of the bundled gems
- It ensures the gems installed via `bundle install` are properly loaded
- The `BUNDLE_PATH`, `BUNDLE_BIN`, and `GEM_HOME` environment variables in the Dockerfile are now properly utilized

## How to Test

### Option 1: Using rebuild.sh (Recommended for testing)

```bash
chmod +x rebuild.sh
./rebuild.sh
docker compose up
```

### Option 2: Using start.sh (Interactive)

```bash
chmod +x start.sh
./start.sh
# Choose option 1 for "Build and run"
```

### Option 3: Manual Commands

```bash
# Stop and remove old containers
docker compose down

# Rebuild without cache
docker compose build --no-cache

# Run the container
docker compose up
```

### To run in background (detached mode)

```bash
docker compose up -d
```

### To view logs

```bash
docker compose logs -f crypto-news-bot
```

### To stop the container

```bash
docker compose down
```

## Verification

After running `docker compose up`, you should see:

1. ✅ No errors about loading `dotenv` or `httparty`
2. ✅ The bot starts successfully
3. ✅ News fetching and processing works correctly

## Additional Files Created

- `rebuild.sh` - Helper script to clean rebuild Docker image

## Notes

- The `.dockerignore` file was already properly configured
- Environment variables are passed correctly via `docker-compose.yml`
- The gems will be installed in `/usr/local/bundle` inside the container
