#!/usr/bin/env ruby

require 'dotenv/load'
require_relative 'news_fetcher'
require 'json'

puts "=" * 80
puts "URL EXTRACTION VALIDATION TEST"
puts "=" * 80
puts

fetcher = NewsFetcher.new
news_data = fetcher.fetch_all_news

total_articles = 0
valid_urls = 0
invalid_urls = 0
errors = []

news_data.each do |source, data|
  puts "\n#{source.to_s.upcase}:"
  puts "  Base URL: #{data[:url]}"
  
  if data[:error]
    puts "  ❌ ERROR: #{data[:error]}"
    errors << "#{source}: #{data[:error]}"
    next
  end
  
  unless data[:content] && data[:content][:headlines]
    puts "  ⚠️  No headlines found"
    next
  end
  
  headlines = data[:content][:headlines]
  puts "  ✓ Found #{headlines.length} articles"
  
  headlines.each_with_index do |headline, idx|
    total_articles += 1
    url = headline[:url]
    title = headline[:title]
    
    # Validate URL
    if url.nil? || url.empty?
      invalid_urls += 1
      puts "  [#{idx + 1}] ❌ EMPTY URL"
      puts "      Title: #{title[0..60]}..."
      errors << "#{source} article #{idx + 1}: Empty URL"
    elsif !url.start_with?('http://') && !url.start_with?('https://')
      invalid_urls += 1
      puts "  [#{idx + 1}] ❌ INVALID URL FORMAT: #{url}"
      puts "      Title: #{title[0..60]}..."
      errors << "#{source} article #{idx + 1}: Invalid URL format - #{url}"
    elsif !url.include?(URI.parse(data[:url]).host.gsub('www.', ''))
      invalid_urls += 1
      puts "  [#{idx + 1}] ⚠️  DOMAIN MISMATCH"
      puts "      Expected: #{URI.parse(data[:url]).host}"
      puts "      Got: #{url}"
      puts "      Title: #{title[0..60]}..."
      errors << "#{source} article #{idx + 1}: Domain mismatch - #{url}"
    else
      valid_urls += 1
      if idx < 2  # Show first 2 valid URLs
        puts "  [#{idx + 1}] ✓ Valid URL"
        puts "      #{url}"
        puts "      #{title[0..60]}..."
      end
    end
  end
end

puts "\n" + "=" * 80
puts "SUMMARY"
puts "=" * 80
puts "Total articles found: #{total_articles}"
puts "Valid URLs: #{valid_urls} (#{(valid_urls.to_f / total_articles * 100).round(1)}%)" if total_articles > 0
puts "Invalid URLs: #{invalid_urls} (#{(invalid_urls.to_f / total_articles * 100).round(1)}%)" if total_articles > 0

if errors.any?
  puts "\n" + "=" * 80
  puts "ERRORS (#{errors.length}):"
  puts "=" * 80
  errors.each do |error|
    puts "  • #{error}"
  end
end

# Save detailed output
output = {
  timestamp: Time.now.to_s,
  summary: {
    total_articles: total_articles,
    valid_urls: valid_urls,
    invalid_urls: invalid_urls
  },
  errors: errors,
  news_data: news_data
}

File.write('url_validation_report.json', JSON.pretty_generate(output))
puts "\n✓ Detailed report saved to url_validation_report.json"
