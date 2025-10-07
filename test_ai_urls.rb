#!/usr/bin/env ruby

require 'dotenv/load'
require_relative 'news_fetcher'
require_relative 'ai_analyzer'
require 'json'

puts "=" * 80
puts "AI URL HANDLING TEST"
puts "=" * 80
puts

# Step 1: Fetch news
puts "Step 1: Fetching news..."
fetcher = NewsFetcher.new
news_data = fetcher.fetch_all_news

# Count and display fetched URLs
fetched_urls = []
news_data.each do |source, data|
  next if data[:error] || !data[:content] || !data[:content][:headlines]
  
  data[:content][:headlines].each do |headline|
    fetched_urls << {
      source: source,
      title: headline[:title],
      url: headline[:url]
    }
  end
end

puts "✓ Fetched #{fetched_urls.length} articles with URLs"
puts "\nSample of fetched URLs:"
fetched_urls.first(5).each_with_index do |item, idx|
  puts "  [#{idx + 1}] #{item[:source]}"
  puts "      URL: #{item[:url]}"
  puts "      Title: #{item[:title][0..60]}..."
  puts
end

# Save the formatted prompt that AI will see
File.write('debug_fetched_urls.json', JSON.pretty_generate(fetched_urls))
puts "✓ All fetched URLs saved to debug_fetched_urls.json"

# Step 2: Analyze with AI
puts "\n" + "=" * 80
puts "Step 2: Sending to AI for analysis..."
puts "=" * 80

analyzer = AIAnalyzer.new(ENV['OPENROUTER_API_KEY'])
ai_result = analyzer.analyze_and_translate(news_data)

if ai_result[:success]
  puts "✓ AI analysis successful"
  puts "  Generated #{ai_result[:messages].length} messages"
  
  # Check returned URLs
  returned_urls = []
  ai_result[:messages].each do |msg|
    url = msg['source_url'] || msg[:source_url]
    returned_urls << {
      title: msg['title'] || msg[:title],
      url: url
    }
  end
  
  puts "\nAI returned URLs:"
  returned_urls.each_with_index do |item, idx|
    puts "  [#{idx + 1}] #{item[:url]}"
    
    # Check if this URL exists in fetched URLs
    if fetched_urls.any? { |f| f[:url] == item[:url] }
      puts "      ✓ Match found in fetched URLs"
    else
      puts "      ❌ NOT FOUND in fetched URLs - AI may have generated this"
    end
  end
  
  # Cross-check
  puts "\n" + "=" * 80
  puts "CROSS-CHECK RESULTS"
  puts "=" * 80
  
  matched = returned_urls.count { |r| fetched_urls.any? { |f| f[:url] == r[:url] } }
  puts "Matched URLs: #{matched}/#{returned_urls.length}"
  puts "Unmatched URLs: #{returned_urls.length - matched}/#{returned_urls.length}"
  
  if matched == returned_urls.length
    puts "\n✅ SUCCESS: All AI-returned URLs match fetched URLs!"
  else
    puts "\n⚠️ WARNING: Some AI-returned URLs don't match!"
    puts "\nUnmatched URLs:"
    returned_urls.each_with_index do |item, idx|
      unless fetched_urls.any? { |f| f[:url] == item[:url] }
        puts "  [#{idx + 1}] #{item[:url]}"
      end
    end
  end
  
  # Save results
  File.write('debug_ai_result.json', JSON.pretty_generate(ai_result))
  puts "\n✓ Full AI result saved to debug_ai_result.json"
  
else
  puts "❌ AI analysis failed"
  puts "Error: #{ai_result[:error]}"
  puts "\nRaw content:"
  puts ai_result[:raw_content][0..500] if ai_result[:raw_content]
end
