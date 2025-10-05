# Crypto News Bot

A Ruby-based cryptocurrency news aggregator and analyzer that:
1. Fetches news from major crypto news sources (CoinDesk, Cointelegraph, The Block, Bitcoin Magazine)
2. Uses AI (OpenRouter) to identify and analyze the top 3 most important stories
3. Translates summaries and analysis to Persian (Farsi)
4. Sends formatted messages to Telegram

## Features

- **Multi-source news aggregation**: Fetches from 4 major crypto news websites
- **AI-powered analysis**: Uses OpenRouter API to identify important stories and provide expert analysis
- **Persian translation**: Automatically translates content to Persian
- **Telegram integration**: Sends beautifully formatted messages to your Telegram channel/chat
- **Dockerized**: Ready to deploy on Ubuntu Server 24.04

## Prerequisites

- Docker and Docker Compose (for containerized deployment)
- OR Ruby 3.x+ and Bundler (for local development)
- OpenRouter API key (required)
- Telegram Bot Token and Chat ID (optional, for Telegram delivery)

## Quick Start with Docker

### 1. Clone the repository

```bash
git clone https://github.com/abmahmoudi1980/crypto-news.git
cd crypto-news
```

### 2. Configure environment variables

Create a `.env` file in the project root:

```bash
cp .env.example .env
```

Edit `.env` and add your credentials:

```env
OPENROUTER_API_KEY=your_openrouter_api_key_here
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here
TELEGRAM_CHAT_ID=your_telegram_chat_id_here
```

**Note**: Only `OPENROUTER_API_KEY` is required. If Telegram credentials are not provided, the bot will output messages to console instead of sending them.

### 3. Build and run with Docker

#### Using Docker Compose (recommended):

```bash
docker-compose up --build
```

To run in detached mode:

```bash
docker-compose up -d --build
```

#### Using Docker directly:

```bash
# Build the image
docker build -t crypto-news-bot .

# Run the container
docker run --env-file .env crypto-news-bot
```

### 4. View logs

```bash
docker-compose logs -f
```

## Local Development (without Docker)

### 1. Install Ruby dependencies

```bash
bundle install
```

### 2. Set up environment variables

```bash
cp .env.example .env
# Edit .env with your credentials
```

### 3. Run the bot

```bash
ruby main.rb
```

## Scheduled Execution

To run the bot on a schedule (e.g., daily), you have several options:

### Option 1: Using cron on host machine

Add to your crontab:

```bash
# Run daily at 9 AM
0 9 * * * cd /path/to/crypto-news && docker-compose up
```

### Option 2: Modify docker-compose.yml

Uncomment the command line in `docker-compose.yml` to run in a loop:

```yaml
command: sh -c "while true; do ruby main.rb && sleep 86400; done"
```

This will run the bot every 24 hours (86400 seconds).

### Option 3: Use an external scheduler

Use tools like:
- Kubernetes CronJob
- AWS EventBridge
- GitHub Actions
- Jenkins

## Output

The bot generates several output files for debugging:

- `fetched_news.json` - Raw news data from all sources
- `ai_analysis.json` - AI analysis results
- `telegram_results.json` - Telegram delivery results
- `ai_error.json` - AI error details (if any)

When using Docker Compose, these files are saved to the `./output` directory on your host machine.

## Docker Commands Reference

```bash
# Build the image
docker-compose build

# Run the bot once
docker-compose up

# Run in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the bot
docker-compose down

# Rebuild and run
docker-compose up --build

# Remove all containers and volumes
docker-compose down -v
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `OPENROUTER_API_KEY` | Yes | Your OpenRouter API key for AI analysis |
| `TELEGRAM_BOT_TOKEN` | No | Telegram bot token from @BotFather |
| `TELEGRAM_CHAT_ID` | No | Telegram chat/channel ID to send messages to |

## Getting API Keys

### OpenRouter API Key
1. Visit [OpenRouter](https://openrouter.ai)
2. Sign up or log in
3. Navigate to API Keys section
4. Create a new API key

### Telegram Bot Token
1. Message [@BotFather](https://t.me/BotFather) on Telegram
2. Send `/newbot` and follow instructions
3. Copy the bot token provided

### Telegram Chat ID
1. Add your bot to a channel/group or start a chat
2. Send a message to the bot
3. Visit `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
4. Find the `chat.id` in the response

## Troubleshooting

### "Missing required environment variables"
- Make sure your `.env` file exists and contains the required keys
- Verify the `.env` file is in the same directory as `docker-compose.yml`

### "AI Analysis failed"
- Check your OpenRouter API key is valid
- Verify you have credits in your OpenRouter account
- Check the `ai_error.json` file for detailed error messages

### "Error fetching news"
- Some news sites may block requests; this is expected
- The bot will continue with available sources
- Check your internet connection

### Docker build fails
- Ensure Docker and Docker Compose are installed
- Check Docker daemon is running: `sudo systemctl status docker`
- Try rebuilding: `docker-compose build --no-cache`

## Project Structure

```
crypto-news/
├── main.rb              # Main bot orchestration
├── news_fetcher.rb      # News scraping from sources
├── ai_analyzer.rb       # OpenRouter API integration
├── telegram_sender.rb   # Telegram Bot API integration
├── Gemfile              # Ruby dependencies
├── Dockerfile           # Docker image definition
├── docker-compose.yml   # Docker Compose configuration
├── .dockerignore        # Docker build exclusions
├── .env.example         # Environment variables template
└── README.md            # This file
```

## Contributing

Feel free to open issues or submit pull requests for improvements.

## License

This project is open source and available under the MIT License.

## Support

For issues and questions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review the troubleshooting section above
