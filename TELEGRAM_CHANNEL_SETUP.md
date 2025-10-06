# How to Send News to Your Public Telegram Channel

The bot already supports sending messages to Telegram channels! You just need to configure it properly.

## Quick Answer

Instead of using a personal chat ID, use your **channel username** (with @ prefix) or **channel ID** as the `TELEGRAM_CHAT_ID`.

## Step-by-Step Setup

### 1. Create a Telegram Bot

If you haven't already:

1. Open Telegram and search for **@BotFather**
2. Send `/newbot` command
3. Follow the prompts to create your bot
4. Copy the **bot token** (looks like: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

### 2. Add Bot to Your Channel

1. Open your Telegram channel
2. Go to **Channel Settings** → **Administrators**
3. Click **Add Administrator**
4. Search for your bot (by username)
5. Add it as an administrator
6. **Important:** Give it permission to **Post Messages**
7. You can disable all other permissions if you want

### 3. Get Your Channel ID

You have **two options**:

#### Option A: Use Channel Username (Easiest for Public Channels)

If your channel is public and has a username like `@YourChannelName`:

```env
TELEGRAM_CHAT_ID=@YourChannelName
```

**Example:**

```env
TELEGRAM_CHAT_ID=@crypto_news_daily
```

#### Option B: Use Channel ID (Works for All Channels)

For private channels or if you prefer using ID:

1. Forward any message from your channel to **@userinfobot**
2. The bot will reply with channel information including the ID
3. Or use this method:
   - Send a test message to your channel
   - Visit: `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
   - Look for your channel's ID (will be a negative number like `-1001234567890`)

```env
TELEGRAM_CHAT_ID=-1001234567890
```

### 4. Update Your .env File

Edit your `.env` file:

```env
# OpenRouter API (Required)
OPENROUTER_API_KEY=sk-or-v1-your-key-here

# Telegram Bot Token (Get from @BotFather)
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz

# Channel ID (use @username for public channels or -100xxx for any channel)
TELEGRAM_CHAT_ID=@your_channel_username
# OR
# TELEGRAM_CHAT_ID=-1001234567890
```

### 5. Test the Configuration

Run the bot:

```bash
docker compose up
```

Or manually test:

```bash
# Create a test script
cat > test_telegram.rb << 'EOF'
require_relative 'telegram_sender'
require 'dotenv/load'

bot_token = ENV['TELEGRAM_BOT_TOKEN']
chat_id = ENV['TELEGRAM_CHAT_ID']

puts "Testing Telegram connection..."
puts "Chat ID: #{chat_id}"

sender = TelegramSender.new(bot_token, chat_id)

test_message = {
  title: "🧪 Test Message",
  body: "This is a test message from Crypto News Bot.\n\nIf you see this, the bot is configured correctly!",
  source_url: "https://github.com/abmahmoudi1980/crypto-news"
}

result = sender.send_message(test_message)

if result[:success]
  puts "✓ Message sent successfully!"
  puts "  Message ID: #{result[:message_id]}"
else
  puts "✗ Failed to send message"
  puts "  Error: #{result[:error]}"
end
EOF

# Run the test
ruby test_telegram.rb
```

## Complete .env Example

```env
# OpenRouter API Key (Required for AI analysis)
# Get from: https://openrouter.ai/
OPENROUTER_API_KEY=sk-or-v1-1234567890abcdefghijklmnopqrstuvwxyz

# Telegram Bot Token (Get from @BotFather)
TELEGRAM_BOT_TOKEN=7123456789:AAEaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQq

# Telegram Channel/Chat ID
# For public channels: use @channelname
# For private channels or groups: use numeric ID (starts with -100)
TELEGRAM_CHAT_ID=@my_crypto_news_channel
```

## Troubleshooting

### Error: "Chat not found"

- ✓ Make sure the bot is added as an administrator to your channel
- ✓ Verify the channel username or ID is correct
- ✓ For usernames, include the @ symbol

### Error: "Bot was blocked by the user"

- This error is for private chats, not channels
- Make sure you're using a channel ID, not a user ID

### Error: "Not enough rights to send text messages"

- ✓ The bot must be an administrator in the channel
- ✓ Enable "Post Messages" permission for the bot

### Bot not posting to channel

- ✓ Verify the bot token is correct
- ✓ Check that TELEGRAM_CHAT_ID uses @ for public channels
- ✓ For private channels, make sure you have the correct channel ID (negative number)

### How to verify channel ID

Create this test script:

```ruby
# verify_channel.rb
require 'httparty'
require 'dotenv/load'

token = ENV['TELEGRAM_BOT_TOKEN']
chat_id = ENV['TELEGRAM_CHAT_ID']

response = HTTParty.get(
  "https://api.telegram.org/bot#{token}/getChat",
  query: { chat_id: chat_id }
)

if response.success?
  chat = response.parsed_response['result']
  puts "✓ Channel found!"
  puts "  Title: #{chat['title']}"
  puts "  Type: #{chat['type']}"
  puts "  ID: #{chat['id']}"
  puts "  Username: @#{chat['username']}" if chat['username']
else
  puts "✗ Error: #{response.parsed_response['description']}"
end
```

Run it:

```bash
ruby verify_channel.rb
```

## Public vs Private Channels

### Public Channels

- Have a username (e.g., `@crypto_news`)
- Can be found in Telegram search
- Use `@username` as TELEGRAM_CHAT_ID

### Private Channels

- Don't have a public username
- Only accessible via invite link
- Must use numeric channel ID (e.g., `-1001234567890`)

## Bot Permissions

Minimum required permissions for the bot in your channel:

- ✅ **Post Messages** (Required)
- ❌ Edit Messages (Optional)
- ❌ Delete Messages (Optional)
- ❌ Add Members (Not needed)
- ❌ Pin Messages (Not needed)

## Example: Complete Setup for Public Channel

```bash
# 1. Create bot via @BotFather
# Bot token: 7123456789:AAEaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQq

# 2. Create public channel: @my_crypto_channel

# 3. Add bot as admin with "Post Messages" permission

# 4. Update .env file:
cat > .env << EOF
OPENROUTER_API_KEY=sk-or-v1-your-actual-key
TELEGRAM_BOT_TOKEN=7123456789:AAEaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQq
TELEGRAM_CHAT_ID=@my_crypto_channel
EOF

# 5. Run the bot
docker compose up
```

## Rate Limits

Telegram has rate limits:

- Channels: 20 messages per minute to the same channel
- The bot already includes 1-second delay between messages (see `telegram_sender.rb`)
- If you send 3 news items, this is well within limits

## Testing

To test without waiting for real news:

```bash
# Run the bot once
docker compose run --rm crypto-news-bot

# Check channel for messages
# Check logs for any errors
docker compose logs
```

## Summary

**For Public Channel:**

```env
TELEGRAM_CHAT_ID=@your_channel_username
```

**For Private Channel:**

```env
TELEGRAM_CHAT_ID=-1001234567890
```

That's it! The bot will now post to your channel instead of sending to a private chat.
