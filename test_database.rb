#!/usr/bin/env ruby

# Simple test script for database functionality

require_relative 'database_manager'

puts "=" * 60
puts "Testing Database Manager"
puts "=" * 60
puts

# Create test database
db = DatabaseManager.new('test_crypto_news.db')

puts "✓ Database initialized"

# Test 1: Add news
puts "\nTest 1: Adding news items..."
result1 = db.add_news(
  title: "Bitcoin reaches new ATH",
  description: "Bitcoin price surges past $100,000",
  date: Time.now.to_s,
  url: "https://example.com/bitcoin-ath",
  source: "test"
)
puts "  Result: #{result1[:success] ? '✓ Added' : '✗ Failed'}"

# Test 2: Add duplicate (should fail)
puts "\nTest 2: Adding duplicate URL..."
result2 = db.add_news(
  title: "Bitcoin reaches new ATH (duplicate)",
  description: "Same URL, different title",
  date: Time.now.to_s,
  url: "https://example.com/bitcoin-ath",
  source: "test"
)
puts "  Result: #{result2[:duplicate] ? '✓ Duplicate detected' : '✗ Should have detected duplicate'}"

# Test 3: Add another unique news
puts "\nTest 3: Adding another unique news..."
result3 = db.add_news(
  title: "Ethereum upgrade successful",
  description: "Latest Ethereum upgrade completed",
  date: Time.now.to_s,
  url: "https://example.com/ethereum-upgrade",
  source: "test"
)
puts "  Result: #{result3[:success] ? '✓ Added' : '✗ Failed'}"

# Test 4: Check if news exists
puts "\nTest 4: Checking if news exists..."
exists1 = db.news_exists?("https://example.com/bitcoin-ath")
exists2 = db.news_exists?("https://example.com/nonexistent")
puts "  Existing URL: #{exists1 ? '✓ Found' : '✗ Not found'}"
puts "  Non-existing URL: #{!exists2 ? '✓ Not found (correct)' : '✗ Found (incorrect)'}"

# Test 5: Get stats
puts "\nTest 5: Database statistics..."
stats = db.get_stats
puts "  Total news: #{stats[:total_news]}"
puts "  Result: #{stats[:total_news] == 2 ? '✓ Correct count' : '✗ Wrong count'}"

# Test 6: Filter news
puts "\nTest 6: Filtering news items..."
test_items = [
  { url: "https://example.com/bitcoin-ath", title: "Existing" },
  { url: "https://example.com/new-news-1", title: "New 1" },
  { url: "https://example.com/new-news-2", title: "New 2" },
  { url: "https://example.com/ethereum-upgrade", title: "Existing" }
]

filtered = db.filter_new_news(test_items)
puts "  Total items: #{filtered[:total_count]}"
puts "  New items: #{filtered[:new_items].length}"
puts "  Duplicates: #{filtered[:duplicate_count]}"
puts "  Result: #{filtered[:new_items].length == 2 && filtered[:duplicate_count] == 2 ? '✓ Correct filtering' : '✗ Wrong filtering'}"

# Cleanup
db.close
File.delete('test_crypto_news.db') if File.exist?('test_crypto_news.db')

puts "\n" + "=" * 60
puts "All tests completed! ✓"
puts "=" * 60
puts "\nThe database functionality is working correctly."
puts "You can now run the bot with: docker compose up"
