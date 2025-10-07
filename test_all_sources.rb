#!/usr/bin/env ruby

require_relative 'news_fetcher'
require 'json'

puts "=" * 80
puts "Testing News Fetching from All Sources"
puts "=" * 80
puts

fetcher = NewsFetcher.new

sources = {
  'CoinDesk' => 'https://www.coindesk.com',
  'Cointelegraph' => 'https://cointelegraph.com',
  'The Block' => 'https://www.theblock.co',
  'Bitcoin Magazine' => 'https://bitcoinmagazine.com'
}

results = {}

sources.each do |name, url|
  puts "\n" + "=" * 80
  puts "Testing: #{name}"
  puts "=" * 80
  
  begin
    result = fetcher.send(:fetch_page_content, url)
    
    if result[:error]
      puts "❌ Error: #{result[:error]}"
      results[name] = { error: result[:error] }
      next
    end
    
    headlines = result[:headlines]
    puts "✓ Fetched successfully!"
    puts "Found #{headlines.length} headlines"
    
    # Show first 3
    headlines.take(3).each_with_index do |headline, idx|
      puts "\n  [#{idx + 1}] #{headline[:title][0..80]}..."
      puts "      URL: #{headline[:url]}"
    end
    
    results[name] = {
      success: true,
      count: headlines.length,
      headlines: headlines
    }
    
    sleep(2) # Be nice to servers
    
  rescue => e
    puts "❌ Exception: #{e.message}"
    results[name] = { error: e.message }
  end
end

# Summary
puts "\n" + "=" * 80
puts "SUMMARY"
puts "=" * 80

sources.each_key do |name|
  if results[name][:success]
    puts "✓ #{name}: #{results[name][:count]} articles"
  else
    puts "✗ #{name}: #{results[name][:error]}"
  end
end

# Save full results
File.write('test_all_sources_output.json', JSON.pretty_generate(results))
puts "\nFull results saved to: test_all_sources_output.json"
