# Production Deployment Guide for Ubuntu Server 24.04

This guide walks you through deploying the Crypto News Bot on a fresh Ubuntu Server 24.04 installation.

## Prerequisites

- Ubuntu Server 24.04 LTS
- Root or sudo access
- Internet connection
- API credentials (OpenRouter API key, optional Telegram credentials)

## Step 1: Update System

```bash
sudo apt update
sudo apt upgrade -y
```

## Step 2: Install Docker

```bash
# Install required packages
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify installation
sudo docker --version
sudo docker compose version

# Add your user to docker group (optional, for non-root access)
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

## Step 3: Clone the Repository

```bash
# Create installation directory
sudo mkdir -p /opt/crypto-news
sudo chown $USER:$USER /opt/crypto-news

# Clone the repository
cd /opt
git clone https://github.com/abmahmoudi1980/crypto-news.git
cd crypto-news
```

## Step 4: Configure Environment Variables

```bash
# Copy the example environment file
cp .env.example .env

# Edit the .env file
nano .env
```

Add your credentials:
```env
OPENROUTER_API_KEY=your_actual_openrouter_api_key_here
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here
TELEGRAM_CHAT_ID=your_telegram_chat_id_here
```

Save and exit (Ctrl+X, then Y, then Enter).

## Step 5: Test the Bot

```bash
# Build the Docker image
docker compose build

# Run the bot once to test
docker compose up

# If successful, you should see output and messages
# Press Ctrl+C to stop
```

## Step 6: Set Up Scheduled Execution (Recommended)

### Using systemd Timer

```bash
# Copy service and timer files
sudo cp crypto-news-bot.service /etc/systemd/system/
sudo cp crypto-news-bot.timer /etc/systemd/system/

# Edit the service file to update paths
sudo nano /etc/systemd/system/crypto-news-bot.service
```

Update these lines in the service file:
```ini
WorkingDirectory=/opt/crypto-news
User=ubuntu  # Change to your username
Group=ubuntu  # Change to your group
```

```bash
# Reload systemd to recognize new files
sudo systemctl daemon-reload

# Enable the timer to start on boot
sudo systemctl enable crypto-news-bot.timer

# Start the timer
sudo systemctl start crypto-news-bot.timer

# Check timer status
sudo systemctl status crypto-news-bot.timer

# List all timers
sudo systemctl list-timers

# Run the service manually once to test
sudo systemctl start crypto-news-bot.service

# View logs
sudo journalctl -u crypto-news-bot.service -f
```

### Using Cron (Alternative)

```bash
# Edit crontab
crontab -e

# Add this line to run daily at 9 AM
0 9 * * * cd /opt/crypto-news && docker compose up

# Save and exit
```

## Step 7: Monitor and Maintain

### View Logs

```bash
# Using systemd
sudo journalctl -u crypto-news-bot.service -f

# Using docker-compose
cd /opt/crypto-news
docker compose logs -f

# View output files
ls -lh /opt/crypto-news/output/
```

### Update the Bot

```bash
cd /opt/crypto-news

# Pull latest changes
git pull

# Rebuild the Docker image
docker compose build

# If using systemd, restart the timer
sudo systemctl restart crypto-news-bot.timer

# If using cron, it will use the new image on next run
```

### Check Container Status

```bash
# List running containers
docker ps

# List all containers
docker ps -a

# View container logs
docker logs crypto-news-bot
```

## Troubleshooting

### Docker Permission Denied

If you get "permission denied" errors:
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

### Bot Fails to Start

Check logs:
```bash
sudo journalctl -u crypto-news-bot.service -n 50
```

Or:
```bash
docker compose logs
```

### Out of Disk Space

Clean up old Docker images:
```bash
docker system prune -a
```

### Port Already in Use

The bot doesn't use any ports, but if you have conflicts:
```bash
docker ps
# Stop conflicting containers
```

### Missing Environment Variables

Verify .env file:
```bash
cat /opt/crypto-news/.env
# Ensure API keys are set
```

## Security Best Practices

1. **Protect your .env file:**
   ```bash
   chmod 600 /opt/crypto-news/.env
   ```

2. **Keep Docker updated:**
   ```bash
   sudo apt update
   sudo apt upgrade docker-ce docker-ce-cli containerd.io
   ```

3. **Regular backups:**
   ```bash
   # Backup your .env file
   cp /opt/crypto-news/.env ~/crypto-news-env-backup
   ```

4. **Monitor logs regularly:**
   ```bash
   sudo journalctl -u crypto-news-bot.service --since "1 day ago"
   ```

5. **Use strong API keys** and rotate them periodically

## Firewall Configuration

If you have a firewall enabled (UFW):

```bash
# The bot doesn't need incoming connections
# But ensure outgoing connections are allowed (default)
sudo ufw status
```

## Uninstallation

To completely remove the bot:

```bash
# Stop and disable timer
sudo systemctl stop crypto-news-bot.timer
sudo systemctl disable crypto-news-bot.timer

# Remove systemd files
sudo rm /etc/systemd/system/crypto-news-bot.service
sudo rm /etc/systemd/system/crypto-news-bot.timer
sudo systemctl daemon-reload

# Remove Docker images
docker compose down --rmi all

# Remove installation directory
sudo rm -rf /opt/crypto-news
```

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [systemd Documentation](https://www.freedesktop.org/software/systemd/man/)
- [OpenRouter API Documentation](https://openrouter.ai/docs)
- [Telegram Bot API Documentation](https://core.telegram.org/bots/api)

## Support

For issues and questions:
- Check the main [README.md](README.md)
- Review logs for error messages
- Open an issue on GitHub
