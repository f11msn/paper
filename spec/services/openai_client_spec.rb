require "rails_helper"

RSpec.describe OpenaiClient do
  let(:api_key) { "test-api-key" }
  let(:client) { described_class.new(api_key:) }
  let(:base_url) { "https://openrouter.ai/api/v1" }

  let(:chat_response) do
    {
      id: "chatcmpl-123",
      object: "chat.completion",
      created: 1_700_000_000,
      model: "deepseek/deepseek-chat",
      choices: [
        {
          index: 0,
          message: { role: "assistant", content: "Привет! Как дела?" },
          finish_reason: "stop"
        }
      ],
      usage: { prompt_tokens: 10, completion_tokens: 8, total_tokens: 18 }
    }
  end

  let(:tool_calls_response) do
    {
      id: "chatcmpl-456",
      choices: [
        {
          index: 0,
          message: {
            role: "assistant",
            content: nil,
            tool_calls: [
              {
                id: "call_abc123",
                type: "function",
                function: {
                  name: "search_news",
                  arguments: '{"query":"нефть"}'
                }
              }
            ]
          },
          finish_reason: "tool_calls"
        }
      ],
      usage: { prompt_tokens: 20, completion_tokens: 15, total_tokens: 35 }
    }
  end

  describe "#chat" do
    before do
      stub_request(:post, "#{base_url}/chat/completions")
        .to_return(status: 200, body: chat_response.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "sends correct headers" do
      client.chat(messages: [{ role: "user", content: "Привет" }])

      expect(WebMock).to have_requested(:post, "#{base_url}/chat/completions")
        .with(headers: {
          "Authorization" => "Bearer test-api-key",
          "Content-Type" => "application/json"
        })
    end

    it "sends model, messages, and parameters in the body" do
      client.chat(
        messages: [{ role: "user", content: "Привет" }],
        temperature: 0.5,
        max_tokens: 2048
      )

      expect(WebMock).to have_requested(:post, "#{base_url}/chat/completions")
        .with(body: hash_including(
          "model" => "deepseek/deepseek-chat",
          "messages" => [{ "role" => "user", "content" => "Привет" }],
          "temperature" => 0.5,
          "max_tokens" => 2048
        ))
    end

    it "parses the response and returns assistant content" do
      result = client.chat(messages: [{ role: "user", content: "Привет" }])

      expect(result.dig("choices", 0, "message", "content")).to eq("Привет! Как дела?")
      expect(result.dig("choices", 0, "message", "role")).to eq("assistant")
    end

    it "uses custom model when provided" do
      custom_client = described_class.new(api_key:, model: "openai/gpt-4o")
      stub_request(:post, "#{base_url}/chat/completions")
        .to_return(status: 200, body: chat_response.to_json, headers: { "Content-Type" => "application/json" })

      custom_client.chat(messages: [{ role: "user", content: "Hi" }])

      expect(WebMock).to have_requested(:post, "#{base_url}/chat/completions")
        .with(body: hash_including("model" => "openai/gpt-4o"))
    end
  end

  describe "#chat with tools" do
    before do
      stub_request(:post, "#{base_url}/chat/completions")
        .to_return(status: 200, body: tool_calls_response.to_json, headers: { "Content-Type" => "application/json" })
    end

    let(:tools) do
      [
        {
          type: "function",
          function: {
            name: "search_news",
            description: "Search news",
            parameters: {
              type: "object",
              properties: { query: { type: "string" } },
              required: ["query"]
            }
          }
        }
      ]
    end

    it "includes tools in the request body" do
      client.chat(messages: [{ role: "user", content: "Новости" }], tools:)

      expect(WebMock).to have_requested(:post, "#{base_url}/chat/completions")
        .with { |req| JSON.parse(req.body).key?("tools") }
    end

    it "returns tool_calls in the response" do
      result = client.chat(messages: [{ role: "user", content: "Новости" }], tools:)
      tool_calls = result.dig("choices", 0, "message", "tool_calls")

      expect(tool_calls).to be_an(Array)
      expect(tool_calls.first["function"]["name"]).to eq("search_news")
    end
  end

  describe "#chat_streaming" do
    let(:sse_chunks) do
      [
        "data: #{{ choices: [{ delta: { role: "assistant" } }] }.to_json}\n\n",
        "data: #{{ choices: [{ delta: { content: "Привет" } }] }.to_json}\n\n",
        "data: #{{ choices: [{ delta: { content: "!" } }] }.to_json}\n\n",
        "data: [DONE]\n\n"
      ].join
    end

    before do
      stub_request(:post, "#{base_url}/chat/completions")
        .to_return(status: 200, body: sse_chunks, headers: { "Content-Type" => "text/event-stream" })
    end

    it "yields parsed chunks to the block" do
      chunks = []
      client.chat_streaming(messages: [{ role: "user", content: "Привет" }]) do |chunk|
        chunks << chunk
      end

      contents = chunks.filter_map { |c| c.dig("choices", 0, "delta", "content") }
      expect(contents).to eq(["Привет", "!"])
    end

    it "sends stream: true in the body" do
      client.chat_streaming(messages: [{ role: "user", content: "Привет" }]) { |_| }

      expect(WebMock).to have_requested(:post, "#{base_url}/chat/completions")
        .with(body: hash_including("stream" => true))
    end
  end

  describe "#last_request_body / #last_response_body" do
    before do
      stub_request(:post, "#{base_url}/chat/completions")
        .to_return(status: 200, body: chat_response.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "stores the last request and response for debugging" do
      client.chat(messages: [{ role: "user", content: "Test" }])

      expect(client.last_request_body).to include("model", "messages")
      expect(client.last_response_body).to include("choices")
    end
  end

  describe "error handling" do
    it "raises on 401 Unauthorized" do
      stub_request(:post, "#{base_url}/chat/completions")
        .to_return(status: 401, body: { error: { message: "Invalid API key" } }.to_json)

      expect {
        client.chat(messages: [{ role: "user", content: "Hi" }])
      }.to raise_error(OpenaiClient::AuthenticationError)
    end

    it "raises on 429 Rate Limited" do
      stub_request(:post, "#{base_url}/chat/completions")
        .to_return(status: 429, body: { error: { message: "Rate limited" } }.to_json)

      expect {
        client.chat(messages: [{ role: "user", content: "Hi" }])
      }.to raise_error(OpenaiClient::RateLimitError)
    end

    it "raises on 500 Server Error" do
      stub_request(:post, "#{base_url}/chat/completions")
        .to_return(status: 500, body: { error: { message: "Internal error" } }.to_json)

      expect {
        client.chat(messages: [{ role: "user", content: "Hi" }])
      }.to raise_error(OpenaiClient::ServerError)
    end
  end
end
