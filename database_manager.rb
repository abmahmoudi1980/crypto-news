require 'sqlite3'
require 'digest'

class DatabaseManager
  def initialize(db_path = 'crypto_news.db')
    # Use absolute path for Docker compatibility
    @db_path = File.directory?('/app') ? "/app/output/#{db_path}" : db_path
    @db = SQLite3::Database.new(@db_path)
    @db.results_as_hash = true
    setup_database
  end

  def setup_database
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS news (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        date TEXT,
        url TEXT NOT NULL UNIQUE,
        url_hash TEXT NOT NULL,
        source TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    SQL

    # Create index for faster lookups
    @db.execute <<-SQL
      CREATE INDEX IF NOT EXISTS idx_url_hash ON news(url_hash);
    SQL

    @db.execute <<-SQL
      CREATE INDEX IF NOT EXISTS idx_created_at ON news(created_at);
    SQL
  end

  def news_exists?(url)
    url_hash = generate_url_hash(url)
    result = @db.get_first_value(
      "SELECT COUNT(*) FROM news WHERE url_hash = ?",
      url_hash
    )
    result.to_i > 0
  end

  def add_news(title:, description: nil, date: nil, url:, source: nil)
    url_hash = generate_url_hash(url)
    
    begin
      @db.execute(
        "INSERT INTO news (title, description, date, url, url_hash, source) VALUES (?, ?, ?, ?, ?, ?)",
        [title, description, date, url, url_hash, source]
      )
      { success: true, id: @db.last_insert_row_id }
    rescue SQLite3::ConstraintException => e
      # Duplicate URL
      { success: false, error: 'Duplicate URL', duplicate: true }
    rescue => e
      { success: false, error: e.message }
    end
  end

  def filter_new_news(news_items)
    new_items = []
    duplicate_count = 0

    news_items.each do |item|
      url = item[:url] || item['url']
      next unless url

      if news_exists?(url)
        duplicate_count += 1
      else
        new_items << item
      end
    end

    {
      new_items: new_items,
      duplicate_count: duplicate_count,
      total_count: news_items.length
    }
  end

  def batch_add_news(news_items)
    results = {
      added: 0,
      duplicates: 0,
      errors: 0
    }

    news_items.each do |item|
      result = add_news(
        title: item[:title] || item['title'],
        description: item[:description] || item['description'],
        date: item[:date] || item['date'],
        url: item[:url] || item['url'],
        source: item[:source] || item['source']
      )

      if result[:success]
        results[:added] += 1
      elsif result[:duplicate]
        results[:duplicates] += 1
      else
        results[:errors] += 1
      end
    end

    results
  end

  def get_recent_news(limit = 100)
    @db.execute(
      "SELECT * FROM news ORDER BY created_at DESC LIMIT ?",
      limit
    )
  end

  def get_stats
    {
      total_news: @db.get_first_value("SELECT COUNT(*) FROM news").to_i,
      sources: @db.execute("SELECT DISTINCT source FROM news WHERE source IS NOT NULL"),
      oldest_entry: @db.get_first_row("SELECT created_at FROM news ORDER BY created_at ASC LIMIT 1"),
      newest_entry: @db.get_first_row("SELECT created_at FROM news ORDER BY created_at DESC LIMIT 1")
    }
  end

  def cleanup_old_news(days = 30)
    deleted = @db.execute(
      "DELETE FROM news WHERE created_at < datetime('now', '-' || ? || ' days')",
      days
    )
    @db.changes
  end

  def close
    @db.close if @db
  end

  private

  def generate_url_hash(url)
    # Normalize URL and generate hash for faster lookups
    normalized_url = url.strip.downcase
    Digest::SHA256.hexdigest(normalized_url)
  end
end
