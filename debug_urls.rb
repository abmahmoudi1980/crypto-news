#!/usr/bin/env ruby

require 'dotenv/load'
require_relative 'news_fetcher'
require 'json'

puts "Testing URL extraction from all sources..."
puts "=" * 80

fetcher = NewsFetcher.new
news_data = fetcher.fetch_all_news

news_data.each do |source, data|
  puts "\n#{source.to_s.upcase}:"
  puts "Base URL: #{data[:url]}"
  
  if data[:error]
    puts "  ERROR: #{data[:error]}"
  elsif data[:content] && data[:content][:headlines]
    puts "  Found #{data[:content][:headlines].length} headlines"
    
    data[:content][:headlines].first(5).each_with_index do |headline, idx|
      puts "\n  [#{idx + 1}]"
      puts "  Title: #{headline[:title][0..80]}..."
      puts "  URL: #{headline[:url]}"
      
      # Test if URL is valid
      if headline[:url].nil? || headline[:url].empty?
        puts "  ⚠️  WARNING: Empty URL!"
      elsif !headline[:url].start_with?('http')
        puts "  ⚠️  WARNING: Invalid URL format!"
      else
        puts "  ✓ URL looks valid"
      end
    end
  else
    puts "  No headlines found"
  end
  
  puts "\n" + "-" * 80
end

# Save full data for inspection
File.write('debug_urls_full.json', JSON.pretty_generate(news_data))
puts "\n✓ Full data saved to debug_urls_full.json"
