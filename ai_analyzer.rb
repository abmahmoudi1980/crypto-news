require 'httparty'
require 'json'

class AIAnalyzer
  OPENROUTER_API_URL = 'https://openrouter.ai/api/v1/chat/completions'

  def initialize(api_key)
    @api_key = api_key
    @headers = {
      'Authorization' => "Bearer #{api_key}",
      'Content-Type' => 'application/json',
      'HTTP-Referer' => 'https://github.com/crypto-news-bot',
      'X-Title' => 'Crypto News Analyzer Bot'
    }
  end

  def analyze_and_translate(news_data)
    puts "Sending news to OpenRouter for analysis..."
    
    prompt = build_analysis_prompt(news_data)
    
    request_body = {
      model: 'deepseek/deepseek-chat-v3.1:free', # You can change to other models
      messages: [
        {
          role: 'user',
          content: prompt
        }
      ],
      temperature: 0.7,
      max_tokens: 4000
    }

    begin
      response = HTTParty.post(
        OPENROUTER_API_URL,
        headers: @headers,
        body: request_body.to_json,
        timeout: 120
      )

      if response.success?
        content = response.parsed_response.dig('choices', 0, 'message', 'content')
        parse_ai_response(content)
      else
        {
          error: "OpenRouter API error: #{response.code} - #{response.body}",
          raw_response: response.body
        }
      end
    rescue => e
      {
        error: "Request failed: #{e.message}",
        exception: e.class.name
      }
    end
  end

  private

  def build_analysis_prompt(news_data)
    news_summary = format_news_for_prompt(news_data)
    
    <<~PROMPT
      You are a cryptocurrency and blockchain expert analyst. Your task is to:

      1. Review ALL the news headlines and content from these four major crypto news sources:
         • CoinDesk
         • Cointelegraph
         • The Block
         • Bitcoin Magazine

      2. Identify the TOP 10 most important crypto/blockchain news stories from today based on:
         - Market impact and significance
         - Technical innovation or developments
         - Regulatory or institutional news
         - Major protocol updates or security issues
         - Trading volume or price action triggers

      3. For each of the top 10 stories, provide:
         a. A concise English summary (2-3 sentences)
         b. Expert analysis covering:
            - Why this matters to the crypto ecosystem
            - Potential market impact (bullish/bearish/neutral)
            - Technical implications if applicable
            - What investors/traders should know

      4. Translate the COMPLETE summary + analysis for each story into fluent, natural Persian (Farsi).

      5. Output ONLY a valid JSON array with exactly 10 objects, each with these fields:
         • title: (Persian headline - clear and engaging)
         • body: (Persian text containing both summary and analysis)
         • source_url: (MUST be the EXACT URL from the headlines below - copy it exactly as provided)

      EXAMPLE of correct source_url usage:
      If you see in the data:
        TITLE: Bitcoin Reaches New All-Time High
        FULL_URL: https://www.coindesk.com/markets/2024/10/07/bitcoin-reaches-new-all-time-high-123456
      
      Then your JSON MUST include:
        "source_url": "https://www.coindesk.com/markets/2024/10/07/bitcoin-reaches-new-all-time-high-123456"
      
      DO NOT use:
        "source_url": "https://www.coindesk.com" ❌ (this is wrong - too generic)
        "source_url": "https://coindesk.com/bitcoin-news" ❌ (this is wrong - made up)

      NEWS DATA:
      #{news_summary}

      CRITICAL INSTRUCTIONS: 
      - Output ONLY the JSON array, no extra text or markdown
      - Ensure valid JSON syntax
      - Persian text must be natural and professional
      - For source_url: Copy the EXACT "FULL_URL:" value from the articles above
      - DO NOT create, modify, or shorten URLs
      - DO NOT use base site URLs
      - Match each story to its original article URL from the data
      - Focus on the most impactful stories

      JSON OUTPUT:
    PROMPT
  end

  def format_news_for_prompt(news_data)
    formatted = []
    
    news_data.each do |source, data|
      next if data[:error]
      
      formatted << "=== #{source.to_s.upcase.gsub('_', ' ')} ==="
      formatted << "Base Site: #{data[:url]}"
      
      if data[:content] && data[:content][:headlines]
        formatted << "\n📰 ARTICLES (#{data[:content][:headlines].length} found):"
        data[:content][:headlines].each_with_index do |headline, idx|
          formatted << "\n[Article #{idx + 1}]"
          formatted << "TITLE: #{headline[:title]}"
          formatted << "FULL_URL: #{headline[:url]}"
          formatted << ""
        end
      end
      
      if data[:content] && data[:content][:text_content]
        formatted << "\nAdditional Context:"
        formatted << data[:content][:text_content][0..1500]
      end
      
      formatted << "\n" + ("=" * 80) + "\n"
    end
    
    formatted.join("\n")
  end

  def parse_ai_response(content)
    # Try to extract JSON from the response
    json_match = content.match(/\[.*\]/m)
    
    if json_match
      json_str = json_match[0]
      begin
        parsed = JSON.parse(json_str)
        
        # Validate structure
        if parsed.is_a?(Array) && parsed.all? { |item| 
          item.is_a?(Hash) && 
          item.key?('title') && 
          item.key?('body') && 
          item.key?('source_url')
        }
          {
            success: true,
            messages: parsed,
            raw_content: content
          }
        else
          {
            success: false,
            error: 'Invalid JSON structure',
            raw_content: content
          }
        end
      rescue JSON::ParserError => e
        {
          success: false,
          error: "JSON parsing failed: #{e.message}",
          raw_content: content
        }
      end
    else
      {
        success: false,
        error: 'No JSON array found in response',
        raw_content: content
      }
    end
  end
end
