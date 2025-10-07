#!/usr/bin/env ruby

require_relative 'news_fetcher'
require 'json'

puts "=" * 80
puts "Testing CoinDesk News Fetching"
puts "=" * 80
puts

fetcher = NewsFetcher.new

puts "Fetching from CoinDesk..."
result = fetcher.send(:fetch_page_content, 'https://www.coindesk.com')

if result[:error]
  puts "❌ Error: #{result[:error]}"
  exit 1
end

headlines = result[:headlines]

puts "✓ Fetched successfully!"
puts
puts "Found #{headlines.length} headlines:"
puts "=" * 80

headlines.each_with_index do |headline, idx|
  puts "\n[#{idx + 1}] #{headline[:title]}"
  puts "    URL: #{headline[:url]}"
  
  # Check if URL looks correct
  if headline[:url] && headline[:url].include?('coindesk.com')
    puts "    ✓ Valid CoinDesk URL"
  elsif headline[:url]
    puts "    ⚠ URL: #{headline[:url]}"
  else
    puts "    ❌ No URL found"
  end
end

puts
puts "=" * 80
puts "Test Complete!"
puts

# Save to file for inspection
File.write('test_coindesk_output.json', JSON.pretty_generate({
  headlines: headlines,
  total: headlines.length,
  sample_html: result[:raw_html][0..5000]
}))

puts "Full output saved to: test_coindesk_output.json"
