require 'httparty'
require 'json'

class TelegramSender
  TELEGRAM_API_URL = 'https://api.telegram.org/bot'

  def initialize(bot_token, chat_id)
    @bot_token = bot_token
    @chat_id = chat_id
    @base_url = "#{TELEGRAM_API_URL}#{bot_token}"
  end

  def send_messages(messages)
    puts "Sending #{messages.length} messages to Telegram..."
    results = []

    messages.each_with_index do |message, index|
      begin
        puts "Sending message #{index + 1}/#{messages.length}..."
        result = send_message(message)
        results << result
        sleep(1) # Rate limiting
      rescue => e
        puts "Error sending message #{index + 1}: #{e.message}"
        results << { error: e.message, message: message }
      end
    end

    results
  end

  def send_message(message_data)
    text = format_message(message_data)
    
    payload = {
      chat_id: @chat_id,
      text: text,
      parse_mode: 'HTML',
      disable_web_page_preview: false
    }

    response = HTTParty.post(
      "#{@base_url}/sendMessage",
      body: payload.to_json,
      headers: { 'Content-Type' => 'application/json' },
      timeout: 30
    )

    if response.success?
      {
        success: true,
        message_id: response.parsed_response.dig('result', 'message_id')
      }
    else
      {
        success: false,
        error: response.parsed_response.dig('description') || 'Unknown error',
        status_code: response.code
      }
    end
  end

  private

  def format_message(data)
    title = data['title'] || data[:title]
    body = data['body'] || data[:body]
    url = data['source_url'] || data[:source_url]

    formatted = "<b>#{escape_html(title)}</b>\n\n"
    formatted += "#{escape_html(body)}\n\n"
    formatted += "🔗 <a href=\"#{url}\">منبع خبر</a>" if url

    # Telegram message limit is 4096 characters
    formatted[0..4090]
  end

  def escape_html(text)
    return '' unless text
    
    text.to_s
        .gsub('&', '&amp;')
        .gsub('<', '&lt;')
        .gsub('>', '&gt;')
  end

  def test_connection
    response = HTTParty.get("#{@base_url}/getMe")
    response.success?
  end
end
