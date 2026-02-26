class OpenaiClient
  class ApiError < StandardError; end
  class AuthenticationError < ApiError; end
  class RateLimitError < ApiError; end
  class ServerError < ApiError; end

  attr_reader :last_request_body, :last_response_body

  DEFAULT_BASE_URL = "https://openrouter.ai/api/v1"
  DEFAULT_MODEL = "deepseek/deepseek-chat"

  def initialize(api_key:, base_url: DEFAULT_BASE_URL, model: DEFAULT_MODEL)
    @api_key = api_key
    @model = model
    @connection = Faraday.new(url: base_url) do |f|
      f.request :json
      f.headers["Authorization"] = "Bearer #{api_key}"
    end
  end

  def chat(messages:, temperature: 0.7, max_tokens: 4096, tools: nil)
    body = build_request_body(messages:, temperature:, max_tokens:, tools:)
    @last_request_body = body.to_json

    response = @connection.post("/api/v1/chat/completions") do |req|
      req.body = body
    end

    @last_response_body = response.body
    handle_errors!(response)
    JSON.parse(response.body)
  end

  def chat_streaming(messages:, temperature: 0.7, max_tokens: 4096, &block)
    body = build_request_body(messages:, temperature:, max_tokens:, stream: true)
    @last_request_body = body.to_json

    buffer = +""

    response = @connection.post("/api/v1/chat/completions") do |req|
      req.body = body
      req.options.on_data = proc do |chunk, _overall_size, _env|
        buffer << chunk
        while (line_end = buffer.index("\n\n"))
          raw_line = buffer.slice!(0..line_end + 1).strip
          next if raw_line.empty?

          data = raw_line.delete_prefix("data: ")
          next if data == "[DONE]"

          parsed = JSON.parse(data)
          block.call(parsed)
        end
      end
    end

    @last_response_body = response.body
  end

  private

  def build_request_body(messages:, temperature:, max_tokens:, tools: nil, stream: false)
    body = {
      model: @model,
      messages:,
      temperature:,
      max_tokens:
    }
    body[:tools] = tools if tools
    body[:stream] = true if stream
    body
  end

  def handle_errors!(response)
    case response.status
    when 200..299
      nil
    when 401
      raise AuthenticationError, error_message(response)
    when 429
      raise RateLimitError, error_message(response)
    when 500..599
      raise ServerError, error_message(response)
    else
      raise ApiError, error_message(response)
    end
  end

  def error_message(response)
    parsed = JSON.parse(response.body)
    parsed.dig("error", "message") || "HTTP #{response.status}"
  rescue JSON::ParserError
    "HTTP #{response.status}: #{response.body}"
  end
end
