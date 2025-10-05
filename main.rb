#!/usr/bin/env ruby

require 'dotenv/load'
require 'json'
require_relative 'news_fetcher'
require_relative 'ai_analyzer'
require_relative 'telegram_sender'

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

      # Step 3: Send to Telegram
      if @telegram_token && @telegram_chat_id
        sender = TelegramSender.new(@telegram_token, @telegram_chat_id)
        results = sender.send_messages(ai_result[:messages])
        
        successful = results.count { |r| r[:success] }
        puts "\n✓ Sent #{successful}/#{results.length} messages to Telegram"
        save_debug_data('telegram_results.json', results)
      else
        puts "\n⚠ Telegram credentials not configured - skipping send"
        puts "Messages ready to send:"
        puts JSON.pretty_generate(ai_result[:messages])
      end

      # Output final JSON
      puts "\n" + "=" * 80
      puts "FINAL OUTPUT - Telegram-Ready Messages:"
      puts "=" * 80
      puts JSON.pretty_generate(ai_result[:messages])
      
    else
      puts "\n✗ AI Analysis failed"
      puts "Error: #{ai_result[:error]}"
      puts "\nRaw response:"
      puts ai_result[:raw_content] if ai_result[:raw_content]
      save_debug_data('ai_error.json', ai_result)
    end

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
