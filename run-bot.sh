# Bash script to run the Crypto News Bot
# For Linux/macOS or Git Bash on Windows

echo "======================================"
echo "Crypto News Bot - Running"
echo "======================================"
echo ""

# Change to the script's directory
cd "$(dirname "$0")"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "✗ Docker is not running"
    echo "Please start Docker and try again."
    exit 1
fi

echo "✓ Docker is running"

# Check if .env file exists
if [ ! -f .env ]; then
    echo "✗ .env file not found!"
    echo "Please create a .env file with your API keys."
    exit 1
fi

echo "✓ Configuration found"
echo ""

# Run the bot
echo "Starting bot..."
docker compose run --rm crypto-news-bot

echo ""
echo "✓ Bot execution completed"
echo "Logs are available in the output directory"
