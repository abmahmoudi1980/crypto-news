#!/usr/bin/env ruby

require_relative 'telegram_sender'
require 'dotenv/load'

puts "=" * 60
puts "Telegram Channel Test"
puts "=" * 60
puts

# Check environment variables
bot_token = ENV['TELEGRAM_BOT_TOKEN']
chat_id = ENV['TELEGRAM_CHAT_ID']

if !bot_token || bot_token.empty? || bot_token.include?('your_')
  puts "❌ TELEGRAM_BOT_TOKEN not configured"
  puts "   Please set it in your .env file"
  exit 1
end

if !chat_id || chat_id.empty? || chat_id.include?('your_')
  puts "❌ TELEGRAM_CHAT_ID not configured"
  puts "   Please set it in your .env file"
  exit 1
end

puts "✓ Configuration found"
puts "  Bot Token: #{bot_token[0..20]}...#{bot_token[-5..-1]}"
puts "  Chat ID: #{chat_id}"
puts

# Initialize sender
sender = TelegramSender.new(bot_token, chat_id)

# Test 1: Verify bot
puts "Test 1: Verifying bot identity..."
begin
  response = HTTParty.get("https://api.telegram.org/bot#{bot_token}/getMe")
  if response.success?
    bot_info = response.parsed_response['result']
    puts "  ✓ Bot verified: @#{bot_info['username']}"
    puts "    Bot ID: #{bot_info['id']}"
    puts "    Name: #{bot_info['first_name']}"
  else
    puts "  ✗ Bot verification failed: #{response.parsed_response['description']}"
    exit 1
  end
rescue => e
  puts "  ✗ Error: #{e.message}"
  exit 1
end

puts

# Test 2: Check channel/chat access
puts "Test 2: Checking channel access..."
begin
  response = HTTParty.get(
    "https://api.telegram.org/bot#{bot_token}/getChat",
    query: { chat_id: chat_id }
  )
  
  if response.success?
    chat_info = response.parsed_response['result']
    puts "  ✓ Channel/Chat found!"
    puts "    Title: #{chat_info['title']}"
    puts "    Type: #{chat_info['type']}"
    puts "    ID: #{chat_info['id']}"
    puts "    Username: @#{chat_info['username']}" if chat_info['username']
    
    if chat_info['type'] == 'channel'
      puts "    ✓ This is a channel - perfect!"
    elsif chat_info['type'] == 'group' || chat_info['type'] == 'supergroup'
      puts "    ⚠ This is a group, not a channel"
    else
      puts "    ⚠ This is a private chat, not a channel"
    end
  else
    puts "  ✗ Cannot access channel: #{response.parsed_response['description']}"
    puts
    puts "  Common issues:"
    puts "    - Bot not added as administrator to the channel"
    puts "    - Channel ID/username is incorrect"
    puts "    - For public channels, use @channelname"
    puts "    - For private channels, use numeric ID (e.g., -1001234567890)"
    exit 1
  end
rescue => e
  puts "  ✗ Error: #{e.message}"
  exit 1
end

puts

# Test 3: Send test message
puts "Test 3: Sending test message..."
test_message = {
  title: "🧪 تست ربات اخبار کریپتو",
  body: "این یک پیام تستی است.\n\nاگر این پیام را مشاهده می‌کنید، ربات به درستی پیکربندی شده است و می‌تواند به کانال شما پست بگذارد.\n\n✅ پیکربندی موفقیت‌آمیز بود!",
  source_url: "https://github.com/abmahmoudi1980/crypto-news"
}

result = sender.send_message(test_message)

if result[:success]
  puts "  ✓ Test message sent successfully!"
  puts "    Message ID: #{result[:message_id]}"
  puts
  puts "  🎉 Check your channel for the test message!"
else
  puts "  ✗ Failed to send message"
  puts "    Error: #{result[:error]}"
  puts "    Status: #{result[:status_code]}"
  
  if result[:error].to_s.include?("rights")
    puts
    puts "  💡 Solution: Make sure the bot has 'Post Messages' permission"
    puts "     1. Go to your channel settings"
    puts "     2. Click on Administrators"
    puts "     3. Find your bot"
    puts "     4. Enable 'Post Messages' permission"
  end
  exit 1
end

puts
puts "=" * 60
puts "✅ All tests passed!"
puts "=" * 60
puts
puts "Your bot is ready to send news to the channel:"
puts "  #{chat_id}"
puts
puts "Run the full bot with: docker compose up"
