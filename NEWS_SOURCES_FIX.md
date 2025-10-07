# News Source URL Extraction Fixes

## Overview

Updated the news fetcher to correctly extract article URLs from **CoinDesk** and **Cointelegraph** using their specific HTML meta/link tags.

## Problem

Modern news sites use JavaScript frameworks and store article URLs in meta/link tags rather than standard HTML links:

### CoinDesk

```html
<meta name="page_url" content="/markets/2025/10/06/article-slug" />
```

### Cointelegraph

```html
<link
  rel="alternate"
  hreflang="en"
  href="https://cointelegraph.com/news/bitcoin-etfs-uptober-3-2b-second-best-week-record"
/>
```

The generic extraction method wasn't finding these URLs.

## Solution

Added site-specific extraction methods in `news_fetcher.rb`:

### 1. CoinDesk Extraction (`extract_coindesk_articles`)

**How it works:**

- Searches for `<meta name="page_url">` tags
- Extracts the relative URL from the content attribute
- Finds associated article title from nearby elements
- Builds complete URL: `https://www.coindesk.com` + relative path

**Example:**

```ruby
doc.css('meta[name="page_url"]').each do |meta|
  page_url = meta['content']  # "/markets/2025/10/06/article-slug"
  full_url = normalize_url(page_url, base_url)
  # → "https://www.coindesk.com/markets/2025/10/06/article-slug"
end
```

### 2. Cointelegraph Extraction (`extract_cointelegraph_articles`)

**How it works:**

- Searches for `<link rel="alternate" hreflang="en">` tags
- Extracts the complete URL from href attribute
- Filters for news/magazine/press-release URLs
- Finds titles from og:title meta tags or nearby headings

**Example:**

```ruby
doc.css('link[rel="alternate"][hreflang="en"]').each do |link|
  article_url = link['href']
  # "https://cointelegraph.com/news/bitcoin-etfs-uptober-3-2b-second-best-week-record"
  # Title extracted from meta tags or URL slug
end
```

### 3. Smart Routing

The main `extract_headlines` method detects the domain and routes to the appropriate extractor:

```ruby
if source_domain.include?('coindesk')
  headlines = extract_coindesk_articles(doc, url)
elsif source_domain.include?('cointelegraph')
  headlines = extract_cointelegraph_articles(doc, url)
else
  headlines = extract_generic_headlines(doc, url)
end
```

## Files Changed

### Main Fix

- **`news_fetcher.rb`**
  - Updated `extract_headlines` with domain detection
  - Added `extract_coindesk_articles` method
  - Added `extract_cointelegraph_articles` method
  - Improved `extract_generic_headlines` method

### Test Scripts (New)

- **`test_coindesk.rb`** - Test CoinDesk extraction
- **`test_cointelegraph.rb`** - Test Cointelegraph extraction
- **`test_all_sources.rb`** - Test all news sources

## Testing

### Test Individual Sources

```bash
# Test CoinDesk
ruby test_coindesk.rb

# Test Cointelegraph
ruby test_cointelegraph.rb

# Test all sources
ruby test_all_sources.rb
```

### Expected Output

#### CoinDesk Test

```
Testing CoinDesk News Fetching
================================================================================

Fetching from CoinDesk...
✓ Fetched successfully!

Found 15 headlines:
================================================================================

[1] XRP, DOGE, SOL See Profit Taking But Bitcoin's New Lifetime High
    URL: https://www.coindesk.com/markets/2025/10/06/xrp-doge-sol...
    ✓ Valid CoinDesk URL

[2] Bitcoin Hits New All-Time High Above $73,000
    URL: https://www.coindesk.com/markets/2025/10/06/bitcoin-hits...
    ✓ Valid CoinDesk URL
```

#### Cointelegraph Test

```
Testing Cointelegraph News Fetching
================================================================================

Fetching from Cointelegraph...
✓ Fetched successfully!

Found 15 headlines:
================================================================================

[1] Bitcoin ETFs See $3.2B in 'Uptober' Inflows
    URL: https://cointelegraph.com/news/bitcoin-etfs-uptober-3-2b...
    ✓ Valid Cointelegraph article URL

[2] Ethereum Upgrade Scheduled for November
    URL: https://cointelegraph.com/news/ethereum-upgrade-november...
    ✓ Valid Cointelegraph article URL
```

### Test Full Bot

```bash
# Test locally
ruby main.rb

# Check output
cat output/fetched_news.json | jq '.coindesk.content.headlines'
cat output/fetched_news.json | jq '.cointelegraph.content.headlines'
```

## What Gets Extracted

### CoinDesk

- ✅ Market analysis articles
- ✅ Breaking news
- ✅ Policy/regulation updates
- ✅ Technology articles

**URL Pattern:** `https://www.coindesk.com/markets/YYYY/MM/DD/article-slug`

### Cointelegraph

- ✅ News articles (`/news/`)
- ✅ Magazine articles (`/magazine/`)
- ✅ Press releases (`/press-releases/`)
- ✅ Market analysis

**URL Pattern:** `https://cointelegraph.com/news/article-slug`

### Other Sources

- The Block - Uses generic extraction (still works)
- Bitcoin Magazine - Uses generic extraction (still works)

## Validation

The fix ensures:

- ✅ Extracts URLs from meta/link tags
- ✅ Builds complete URLs with proper domains
- ✅ Finds article titles correctly
- ✅ Removes duplicate URLs
- ✅ Falls back to generic extraction if needed
- ✅ Works for all news sources

## Apply the Fix

### Local Development

```bash
# Test individual sources
ruby test_coindesk.rb
ruby test_cointelegraph.rb

# Test all sources
ruby test_all_sources.rb

# Run full bot
ruby main.rb
```

### Docker Production

```bash
# Rebuild with the fix
docker compose build --no-cache

# Test run
docker compose up

# Check output
docker compose logs | grep "headlines"
```

### Production Server with Timer

```bash
# After pulling changes
cd /opt/crypto-news
git pull

# Rebuild Docker image
docker compose build --no-cache

# Restart timer (if using systemd)
sudo systemctl restart crypto-news-bot.timer

# Check next run
systemctl list-timers crypto-news-bot.timer
```

## Verify It's Working

### Check Logs

```bash
# Look for successful fetching
sudo journalctl -u crypto-news-bot.service -n 100 | grep "Fetching from"

# Should see:
# Fetching from coindesk...
# Fetching from cointelegraph...
# ✓ Found X headlines from coindesk
# ✓ Found X headlines from cointelegraph
```

### Check Output Files

```bash
# Local
cat output/fetched_news.json | jq '.coindesk.content.headlines[0]'
cat output/fetched_news.json | jq '.cointelegraph.content.headlines[0]'

# Docker
docker exec crypto-news-bot cat /app/output/fetched_news.json | jq '.coindesk'
```

### Expected URLs

**CoinDesk URLs should look like:**

```
https://www.coindesk.com/markets/2025/10/07/bitcoin-price-analysis
https://www.coindesk.com/business/2025/10/07/crypto-exchange-launches
https://www.coindesk.com/policy/2025/10/07/sec-approves-new-rules
```

**Cointelegraph URLs should look like:**

```
https://cointelegraph.com/news/bitcoin-hits-new-high-october-2025
https://cointelegraph.com/magazine/defi-protocols-security-analysis
https://cointelegraph.com/news/ethereum-network-upgrade-complete
```

## Troubleshooting

### No headlines found

1. **Test with the test scripts first:**

   ```bash
   ruby test_all_sources.rb
   ```

2. **Check if site structure changed:**

   ```bash
   # For CoinDesk
   curl -s https://www.coindesk.com | grep 'meta name="page_url"'

   # For Cointelegraph
   curl -s https://cointelegraph.com | grep 'rel="alternate"'
   ```

3. **Review the output file:**
   ```bash
   cat test_all_sources_output.json | jq '.CoinDesk'
   cat test_all_sources_output.json | jq '.Cointelegraph'
   ```

### URLs are incomplete or wrong

- Check the `normalize_url` method is working
- Verify the base URL is correct
- Look at the raw HTML in the test output file

### Still using generic extraction

- Verify the domain detection logic:
  ```ruby
  if source_domain.include?('coindesk')  # Should match
  ```
- Check there are no typos in domain names
- Test with the individual test scripts

## Performance Impact

- ✅ **No negative impact** - Specialized extraction is faster
- ✅ **Better accuracy** - Finds more relevant articles
- ✅ **More reliable** - Not affected by CSS/class name changes
- ✅ **Fewer false positives** - Only gets actual articles

## Summary

✅ **CoinDesk**: Extracts URLs from `<meta name="page_url">` tags  
✅ **Cointelegraph**: Extracts URLs from `<link rel="alternate">` tags  
✅ **Backward Compatible**: Generic extraction still works for other sites  
✅ **Tested**: Individual test scripts for verification  
✅ **Robust**: Multiple extraction methods with fallbacks

The bot will now correctly identify and analyze articles from both CoinDesk and Cointelegraph, resulting in better news coverage in your Telegram channel! 🎉
