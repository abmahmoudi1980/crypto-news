# PowerShell script to run the Crypto News Bot
# Save as run-bot.ps1 and use with Task Scheduler for automatic runs

Write-Host "======================================"
Write-Host "Crypto News Bot - Running"
Write-Host "======================================"
Write-Host ""

# Change to the script's directory
Set-Location $PSScriptRoot

# Check if Docker is running
try {
    docker info | Out-Null
    Write-Host "✓ Docker is running" -ForegroundColor Green
}
catch {
    Write-Host "✗ Docker is not running" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again."
    exit 1
}

# Check if .env file exists
if (-Not (Test-Path ".env")) {
    Write-Host "✗ .env file not found!" -ForegroundColor Red
    Write-Host "Please create a .env file with your API keys."
    exit 1
}

Write-Host "✓ Configuration found" -ForegroundColor Green
Write-Host ""

# Run the bot
Write-Host "Starting bot..." -ForegroundColor Cyan
docker compose run --rm crypto-news-bot

Write-Host ""
Write-Host "✓ Bot execution completed" -ForegroundColor Green
Write-Host "Logs are available in the output directory"
