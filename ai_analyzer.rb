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
      model: 'z-ai/glm-4.6', # You can change to other models
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

      2. Identify the TOP 3 most important crypto/blockchain news stories from today based on:
         - Market impact and significance
         - Technical innovation or developments
         - Regulatory or institutional news
         - Major protocol updates or security issues
         - Trading volume or price action triggers

      3. For each of the top 3 stories, provide:
         a. A concise English summary (2-3 sentences)
         b. Expert analysis covering:
            - Why this matters to the crypto ecosystem
            - Potential market impact (bullish/bearish/neutral)
            - Technical implications if applicable
            - What investors/traders should know

      4. Translate the COMPLETE summary + analysis for each story into fluent, natural Persian (Farsi).

      5. Output ONLY a valid JSON array with exactly 3 objects, each with these fields:
         • title: (Persian headline - clear and engaging)
         • body: (Persian text containing both summary and analysis)
         • source_url: (original article URL from the source)

      NEWS DATA:
      #{news_summary}

      IMPORTANT: 
      - Output ONLY the JSON array, no extra text
      - Ensure valid JSON syntax
      - Persian text must be natural and professional
      - Include actual URLs from the sources provided
      - Focus on the most impactful stories

      JSON OUTPUT:
    PROMPT
  end

  def format_news_for_prompt(news_data)
    formatted = []
    
    news_data.each do |source, data|
      next if data[:error]
      
      formatted << "=== #{source.to_s.upcase.gsub('_', ' ')} ==="
      formatted << "URL: #{data[:url]}"
      
      if data[:content] && data[:content][:headlines]
        formatted << "\nHeadlines:"
        data[:content][:headlines].each_with_index do |headline, idx|
          formatted << "#{idx + 1}. #{headline[:title]}"
          formatted << "   URL: #{headline[:url]}" if headline[:url]
        end
      end
      
      if data[:content] && data[:content][:text_content]
        formatted << "\nContent Preview:"
        formatted << data[:content][:text_content][0..2000]
      end
      
      formatted << "\n" + ("-" * 80) + "\n"
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
