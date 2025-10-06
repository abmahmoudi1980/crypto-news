# Quick Setup: Send to Telegram Channel

## TL;DR - 5 Steps

### 1️⃣ Create Bot

- Open Telegram → Search **@BotFather**
- Send `/newbot`
- Get your bot token: `123456789:ABCdef...`

### 2️⃣ Create/Open Your Channel

- Create a public channel or use existing one
- Note the username (e.g., `@my_crypto_news`)

### 3️⃣ Add Bot as Admin

- Channel Settings → Administrators → Add Administrator
- Search for your bot → Add it
- ✅ Enable **"Post Messages"** permission
- Save

### 4️⃣ Configure .env

```env
OPENROUTER_API_KEY=sk-or-v1-your-key
TELEGRAM_BOT_TOKEN=123456789:ABCdef...
TELEGRAM_CHAT_ID=@my_crypto_news
```

### 5️⃣ Test & Run

```bash
# Test configuration
ruby test_telegram.rb

# Run the bot
docker compose up
```

---

## Visual Flow

```
┌─────────────────────────────────────────────┐
│  Step 1: Talk to @BotFather                │
│  /newbot → Get Bot Token                   │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Step 2: Your Channel                      │
│  Example: @crypto_news_daily               │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Step 3: Add Bot to Channel                │
│  - Go to Administrators                    │
│  - Add your bot                            │
│  - Enable "Post Messages"                  │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Step 4: Update .env                       │
│  TELEGRAM_CHAT_ID=@crypto_news_daily       │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Step 5: Run & Enjoy! 🎉                   │
│  News will be posted to your channel       │
└─────────────────────────────────────────────┘
```

---

## Channel ID Options

### For Public Channel (Recommended)

```env
TELEGRAM_CHAT_ID=@your_channel_username
```

✅ Easy to use
✅ No need to find numeric ID
✅ Human-readable

### For Private Channel

```env
TELEGRAM_CHAT_ID=-1001234567890
```

Use this if your channel doesn't have a public username.

**How to find numeric ID:**

1. Forward a message from your channel to **@userinfobot**
2. It will reply with the channel ID
3. Copy the number (including the minus sign)

---

## Verify Setup

```bash
# Test your configuration
ruby test_telegram.rb
```

This will:

- ✓ Verify bot token is valid
- ✓ Check bot can access the channel
- ✓ Send a test message
- ✓ Confirm everything works

---

## Common Issues

### "Chat not found"

→ Bot not added as admin to channel
→ Wrong channel username/ID

### "Not enough rights"

→ Bot doesn't have "Post Messages" permission
→ Go to channel admins and enable it

### "Bot was blocked"

→ You're using private chat ID instead of channel
→ Use channel username with @ or channel numeric ID

---

## Test Message

When you run `test_telegram.rb`, you'll see a test message in Persian in your channel:

```
🧪 تست ربات اخبار کریپتو

این یک پیام تستی است.

اگر این پیام را مشاهده می‌کنید، ربات به درستی پیکربندی شده است...

✅ پیکربندی موفقیت‌آمیز بود!

🔗 منبع خبر
```

---

## Ready! 🚀

Once the test passes, run the full bot:

```bash
docker compose up
```

News will be automatically posted to your channel every time the bot runs!
