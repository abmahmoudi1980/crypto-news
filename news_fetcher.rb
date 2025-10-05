require 'httparty'
require 'nokogiri'
require 'json'

class NewsFetcher
  SOURCES = {
    coindesk: 'https://www.coindesk.com',
    cointelegraph: 'https://cointelegraph.com',
    theblock: 'https://www.theblock.co',
    bitcoin_magazine: 'https://bitcoinmagazine.com'
  }

  def initialize
    @headers = {
      'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
  end

  def fetch_all_news
    puts "Fetching news from all sources..."
    results = {}

    SOURCES.each do |source_name, url|
      begin
        puts "Fetching from #{source_name}..."
        content = fetch_page_content(url)
        results[source_name] = {
          url: url,
          content: content,
          fetched_at: Time.now
        }
        sleep(1) # Be polite to servers
      rescue => e
        puts "Error fetching #{source_name}: #{e.message}"
        results[source_name] = {
          url: url,
          error: e.message,
          fetched_at: Time.now
        }
      end
    end

    results
  end

  private

  def fetch_page_content(url)
    response = HTTParty.get(url, headers: @headers, follow_redirects: true, timeout: 30)
    
    if response.success?
      doc = Nokogiri::HTML(response.body)
      
      # Remove script and style tags
      doc.css('script, style, nav, footer, iframe, ads').each(&:remove)
      
      # Extract headlines and summaries
      headlines = extract_headlines(doc, url)
      
      {
        raw_html: response.body[0..50000], # Limit size
        headlines: headlines,
        text_content: doc.css('body').text.gsub(/\s+/, ' ').strip[0..10000]
      }
    else
      { error: "HTTP #{response.code}" }
    end
  end

  def extract_headlines(doc, url)
    headlines = []
    
    # Common selectors for news headlines
    selectors = [
      'article h2', 'article h3', 'article h4',
      '.headline', '.article-title', '.post-title',
      'h1 a', 'h2 a', 'h3 a',
      '[class*="headline"]', '[class*="title"]'
    ]
    
    selectors.each do |selector|
      doc.css(selector).each do |element|
        text = element.text.strip
        next if text.empty? || text.length < 20
        
        link = element.css('a').first&.attr('href') || element.attr('href')
        link = normalize_url(link, url) if link
        
        headlines << {
          title: text[0..300],
          url: link
        }
        
        break if headlines.length >= 15
      end
      break if headlines.length >= 10
    end
    
    headlines.uniq { |h| h[:title] }
  end

  def normalize_url(link, base_url)
    return link if link.start_with?('http')
    
    base_uri = URI.parse(base_url)
    if link.start_with?('//')
      "https:#{link}"
    elsif link.start_with?('/')
      "#{base_uri.scheme}://#{base_uri.host}#{link}"
    else
      "#{base_uri.scheme}://#{base_uri.host}/#{link}"
    end
  rescue
    link
  end
end
