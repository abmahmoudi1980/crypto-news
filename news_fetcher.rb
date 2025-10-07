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
    base_uri = URI.parse(url)
    source_domain = base_uri.host
    
    # Special handling for CoinDesk - extract from meta tags
    if source_domain.include?('coindesk')
      headlines = extract_coindesk_articles(doc, url)
    # Special handling for Cointelegraph - extract from link tags
    elsif source_domain.include?('cointelegraph')
      headlines = extract_cointelegraph_articles(doc, url)
    end
    
    # If no headlines from special extraction or other sites, use generic method
    if headlines.empty?
      headlines = extract_generic_headlines(doc, url)
    end
    
    headlines.uniq { |h| h[:url] }.take(15)
  end

  def extract_coindesk_articles(doc, base_url)
    articles = []
    
    # Method 1: Extract from meta tags (most reliable for CoinDesk)
    doc.css('meta[name="page_url"]').each do |meta|
      page_url = meta['content']
      next unless page_url
      
      # Find associated title
      article_element = meta.parent
      title = nil
      
      # Try to find title in nearby elements
      if article_element
        title_element = article_element.at_css('h1, h2, h3, h4, .title, [class*="headline"]')
        title = title_element&.text&.strip if title_element
      end
      
      # If no title found, use the URL to extract it
      unless title && title.length > 20
        title = page_url.split('/')[-1]&.gsub('-', ' ')&.capitalize
      end
      
      next if title.to_s.length < 10
      
      full_url = normalize_url(page_url, base_url)
      
      articles << {
        title: title[0..300],
        url: full_url
      }
    end
    
    # Method 2: Look for article cards with data attributes
    doc.css('article, [class*="article"], [class*="card"]').each do |article|
      title_elem = article.at_css('h1, h2, h3, h4, [class*="title"], [class*="headline"]')
      link_elem = article.at_css('a[href*="/markets/"], a[href*="/business/"], a[href*="/tech/"], a[href*="/policy/"]')
      
      if title_elem && link_elem
        title = title_elem.text.strip
        link = link_elem['href']
        
        next if title.empty? || title.length < 20
        
        articles << {
          title: title[0..300],
          url: normalize_url(link, base_url)
        }
      end
      
      break if articles.length >= 15
    end
    
    articles
  end

  def extract_cointelegraph_articles(doc, base_url)
    articles = []
    
    # Method 1: Extract from link alternate tags (most reliable for Cointelegraph)
    doc.css('link[rel="alternate"][hreflang="en"]').each do |link|
      article_url = link['href']
      next unless article_url
      next unless article_url.include?('cointelegraph.com/news') || 
                  article_url.include?('cointelegraph.com/magazine') ||
                  article_url.include?('cointelegraph.com/press-releases')
      
      # Find associated title - look in nearby meta tags or headings
      title = nil
      
      # Try og:title meta tag
      og_title = doc.at_css('meta[property="og:title"]')
      title = og_title['content'] if og_title
      
      # Try to find title in the document structure
      unless title && title.length > 20
        # Look for the heading near this link element
        parent = link.parent
        if parent
          title_elem = parent.at_css('h1, h2, h3, .title, [class*="headline"]')
          title = title_elem&.text&.strip if title_elem
        end
      end
      
      # If still no title, extract from URL
      unless title && title.length > 20
        title = article_url.split('/')[-1]&.gsub('-', ' ')&.capitalize
      end
      
      next if title.to_s.length < 10
      
      articles << {
        title: title[0..300],
        url: article_url
      }
      
      break if articles.length >= 15
    end
    
    # Method 2: Look for article elements with links
    if articles.length < 10
      doc.css('article, [class*="post"], [class*="article"]').each do |article|
        title_elem = article.at_css('h1, h2, h3, h4, [class*="title"], [class*="headline"]')
        link_elem = article.at_css('a[href*="/news/"], a[href*="/magazine/"]')
        
        if title_elem && link_elem
          title = title_elem.text.strip
          link = link_elem['href']
          
          next if title.empty? || title.length < 20
          next unless link
          
          full_url = link.start_with?('http') ? link : normalize_url(link, base_url)
          
          articles << {
            title: title[0..300],
            url: full_url
          }
        end
        
        break if articles.length >= 15
      end
    end
    
    articles
  end

  def extract_generic_headlines(doc, url)
    headlines = []
    
    # Common selectors for news headlines
    selectors = [
      'article h2 a', 'article h3 a', 'article h4 a',
      '.headline a', '.article-title a', '.post-title a',
      'h2 a', 'h3 a',
      '[class*="headline"] a', '[class*="title"] a',
      'article a'
    ]
    
    selectors.each do |selector|
      doc.css(selector).each do |element|
        link = element['href']
        next unless link
        
        # Get text from the link or parent element
        text = element.text.strip
        if text.empty? || text.length < 20
          text = element.parent&.text&.strip
        end
        
        next if text.to_s.empty? || text.length < 20
        
        # Skip navigation/footer links
        next if link.match?(/^\/(about|contact|privacy|terms|category|tag|author)/)
        
        full_url = normalize_url(link, url)
        
        headlines << {
          title: text[0..300],
          url: full_url
        }
        
        break if headlines.length >= 20
      end
      break if headlines.length >= 15
    end
    
    headlines
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
