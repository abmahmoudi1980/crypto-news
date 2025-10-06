#!/usr/bin/env ruby

require 'dotenv/load'
require 'json'
require_relative 'news_fetcher'
require_relative 'ai_analyzer'
require_relative 'telegram_sender'
require_relative 'database_manager'

class CryptoNewsBot
  def initialize
    @openrouter_key = ENV['OPENROUTER_API_KEY']
    @telegram_token = ENV['TELEGRAM_BOT_TOKEN']
    @telegram_chat_id = ENV['TELEGRAM_CHAT_ID']

    validate_environment
  end

  def run
    puts "=" * 80
    puts "Crypto News Bot - Starting at #{Time.now}"
    puts "=" * 80
    puts

    # Initialize database
    db = DatabaseManager.new
    
    # Step 1: Fetch news from all sources
    fetcher = NewsFetcher.new
    news_data = fetcher.fetch_all_news
    
    puts "\nNews fetched successfully from #{news_data.keys.length} sources"
    save_debug_data('fetched_news.json', news_data)

    # Step 2: Analyze with AI and get Persian translations
    analyzer = AIAnalyzer.new(@openrouter_key)
    ai_result = analyzer.analyze_and_translate(news_data)
    
    if ai_result[:success]
      puts "\n✓ AI Analysis completed successfully"
      puts "Generated #{ai_result[:messages].length} Telegram-ready messages"
      save_debug_data('ai_analysis.json', ai_result)

      # Step 3: Filter out duplicate news using database
      new_messages = []
      duplicate_count = 0
      
      ai_result[:messages].each do |message|
        url = message['source_url'] || message[:source_url]
        title = message['title'] || message[:title]
        body = message['body'] || message[:body]
        
        if url && !db.news_exists?(url)
          new_messages << message
          # Add to database
          db.add_news(
            title: title,
            description: body,
            date: Time.now.to_s,
            url: url,
            source: 'ai_analyzed'
          )
        else
          duplicate_count += 1
          puts "  → Skipping duplicate news: #{title[0..50]}..."
        end
      end

      puts "\n✓ Filtered results: #{new_messages.length} new, #{duplicate_count} duplicates"

      # Step 4: Send only new messages to Telegram
      if new_messages.any?
        if @telegram_token && @telegram_chat_id
          sender = TelegramSender.new(@telegram_token, @telegram_chat_id)
          results = sender.send_messages(new_messages)
          
          successful = results.count { |r| r[:success] }
          puts "\n✓ Sent #{successful}/#{new_messages.length} new messages to Telegram"
          save_debug_data('telegram_results.json', results)
        else
          puts "\n⚠ Telegram credentials not configured - skipping send"
          puts "New messages ready to send:"
          puts JSON.pretty_generate(new_messages)
        end

        # Output final JSON
        puts "\n" + "=" * 80
        puts "FINAL OUTPUT - New Telegram Messages (#{new_messages.length}):"
        puts "=" * 80
        puts JSON.pretty_generate(new_messages)
      else
        puts "\n⚠ No new messages to send - all news items were duplicates"
      end
      
      # Show database stats
      stats = db.get_stats
      puts "\n" + "=" * 80
      puts "Database Statistics:"
      puts "  Total news stored: #{stats[:total_news]}"
      puts "=" * 80
      
    else
      puts "\n✗ AI Analysis failed"
      puts "Error: #{ai_result[:error]}"
      puts "\nRaw response:"
      puts ai_result[:raw_content] if ai_result[:raw_content]
      save_debug_data('ai_error.json', ai_result)
    end

    db.close
    
    puts "\n" + "=" * 80
    puts "Bot execution completed at #{Time.now}"
    puts "=" * 80
  end

  private

  def validate_environment
    errors = []
    errors << "OPENROUTER_API_KEY" unless @openrouter_key
    
    if errors.any?
      puts "ERROR: Missing required environment variables:"
      errors.each { |var| puts "  - #{var}" }
      puts "\nPlease set these in your .env file"
      exit(1)
    end

    if !@telegram_token || !@telegram_chat_id
      puts "⚠ WARNING: Telegram credentials not configured"
      puts "Messages will be displayed but not sent to Telegram"
      puts
    end
  end

  def save_debug_data(filename, data)
    # Create output directory if it doesn't exist
    output_dir = File.directory?('/app/output') ? '/app/output' : '.'
    filepath = File.join(output_dir, filename)
    
    File.write(filepath, JSON.pretty_generate(data))
    puts "  → Debug data saved to #{filepath}"
  rescue => e
    puts "  → Could not save debug data: #{e.message}"
  end
end

# Run the bot
if __FILE__ == $0
  begin
    bot = CryptoNewsBot.new
    bot.run
  rescue Interrupt
    puts "\n\nBot interrupted by user"
    exit(0)
  rescue => e
    puts "\n✗ Fatal error: #{e.message}"
    puts e.backtrace.first(5)
    exit(1)
  end
end
