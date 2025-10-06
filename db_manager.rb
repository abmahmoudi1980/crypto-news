#!/usr/bin/env ruby

require_relative 'database_manager'
require 'json'

def show_help
  puts <<~HELP
    Database Manager Utility
    ========================
    
    Usage: ruby db_manager.rb [command] [options]
    
    Commands:
      stats                 - Show database statistics
      list [limit]          - List recent news (default: 20)
      search <keyword>      - Search news by keyword
      cleanup <days>        - Delete news older than X days
      export <file>         - Export all news to JSON file
      reset                 - Clear all news (WARNING: irreversible)
      
    Examples:
      ruby db_manager.rb stats
      ruby db_manager.rb list 50
      ruby db_manager.rb cleanup 30
      ruby db_manager.rb export backup.json
  HELP
end

def show_stats(db)
  stats = db.get_stats
  
  puts "\n" + "=" * 60
  puts "DATABASE STATISTICS"
  puts "=" * 60
  puts "Total news entries: #{stats[:total_news]}"
  puts "Oldest entry: #{stats[:oldest_entry]&.first}" if stats[:oldest_entry]
  puts "Newest entry: #{stats[:newest_entry]&.first}" if stats[:newest_entry]
  puts "=" * 60
end

def list_news(db, limit = 20)
  news = db.get_recent_news(limit)
  
  puts "\n" + "=" * 60
  puts "RECENT NEWS (#{news.length} items)"
  puts "=" * 60
  
  news.each_with_index do |item, idx|
    puts "\n[#{idx + 1}] #{item['title']}"
    puts "    URL: #{item['url']}"
    puts "    Date: #{item['created_at']}"
    puts "    Source: #{item['source']}" if item['source']
  end
  
  puts "=" * 60
end

def cleanup_old_news(db, days)
  puts "Cleaning up news older than #{days} days..."
  deleted = db.cleanup_old_news(days)
  puts "✓ Deleted #{deleted} old news entries"
end

def export_news(db, filename)
  news = db.get_recent_news(100000) # Get all
  
  File.write(filename, JSON.pretty_generate(news))
  puts "✓ Exported #{news.length} news items to #{filename}"
end

def reset_database(db)
  print "Are you sure you want to delete ALL news? Type 'yes' to confirm: "
  confirmation = gets.chomp
  
  if confirmation.downcase == 'yes'
    db.instance_variable_get(:@db).execute("DELETE FROM news")
    puts "✓ Database reset complete"
  else
    puts "Cancelled"
  end
end

# Main
command = ARGV[0]

if command.nil? || command == 'help'
  show_help
  exit 0
end

begin
  db = DatabaseManager.new
  
  case command
  when 'stats'
    show_stats(db)
    
  when 'list'
    limit = (ARGV[1] || 20).to_i
    list_news(db, limit)
    
  when 'cleanup'
    days = (ARGV[1] || 30).to_i
    cleanup_old_news(db, days)
    
  when 'export'
    filename = ARGV[1] || "news_export_#{Time.now.strftime('%Y%m%d_%H%M%S')}.json"
    export_news(db, filename)
    
  when 'reset'
    reset_database(db)
    
  else
    puts "Unknown command: #{command}"
    puts "Run 'ruby db_manager.rb help' for usage information"
    exit 1
  end
  
  db.close
  
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(3)
  exit 1
end
