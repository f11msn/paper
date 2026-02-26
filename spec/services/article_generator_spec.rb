require "rails_helper"

RSpec.describe ArticleGenerator do
  let(:api_key) { "test-key" }
  let(:client) { OpenaiClient.new(api_key:) }
  let(:generator) { described_class.new(client:) }
  let(:base_url) { "https://openrouter.ai/api/v1" }

  let(:system_prompt) { "Ты — журналист Коммерсанта" }
  let(:topic) { "рост цен на нефть" }
  let(:rubric) { "Экономика" }

  let(:text_response) do
    {
      choices: [
        {
          message: { role: "assistant", content: "# Нефть пошла в рост\n\nКак стало известно Ъ..." },
          finish_reason: "stop"
        }
      ]
    }
  end

  let(:tool_calls_response) do
    {
      choices: [
        {
          message: {
            role: "assistant",
            content: nil,
            tool_calls: [
              {
                id: "call_001",
                type: "function",
                function: { name: "search_news", arguments: '{"query":"нефть цены"}' }
              }
            ]
          },
          finish_reason: "tool_calls"
        }
      ]
    }
  end

  describe "#generate" do
    context "without tool calls" do
      before do
        stub_request(:post, "#{base_url}/chat/completions")
          .to_return(status: 200, body: text_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "returns content, api_log, and tool_calls_log" do
        result = generator.generate(topic:, rubric:, system_prompt:)

        expect(result[:content]).to include("Нефть пошла в рост")
        expect(result[:api_log]).to be_an(Array)
        expect(result[:api_log]).not_to be_empty
        expect(result[:tool_calls_log]).to be_an(Array)
      end

      it "sends system prompt as first message" do
        generator.generate(topic:, rubric:, system_prompt:)

        expect(WebMock).to have_requested(:post, "#{base_url}/chat/completions")
          .with { |req|
            messages = JSON.parse(req.body)["messages"]
            messages.first["role"] == "system" && messages.first["content"].include?("журналист")
          }
      end

      it "includes topic and rubric in user message" do
        generator.generate(topic:, rubric:, system_prompt:)

        expect(WebMock).to have_requested(:post, "#{base_url}/chat/completions")
          .with { |req|
            messages = JSON.parse(req.body)["messages"]
            user_msg = messages.find { |m| m["role"] == "user" }
            user_msg["content"].include?(topic) && user_msg["content"].include?(rubric)
          }
      end
    end

    context "with tool calls" do
      before do
        stub_request(:post, "#{base_url}/chat/completions")
          .to_return(
            { status: 200, body: tool_calls_response.to_json, headers: { "Content-Type" => "application/json" } },
            { status: 200, body: text_response.to_json, headers: { "Content-Type" => "application/json" } }
          )
      end

      it "executes the tool calling loop and returns final content" do
        result = generator.generate(topic:, rubric:, system_prompt:)

        expect(result[:content]).to include("Нефть пошла в рост")
        expect(result[:tool_calls_log]).not_to be_empty
        expect(result[:tool_calls_log].first[:function_name]).to eq("search_news")
      end

      it "sends tool result back to the API" do
        generator.generate(topic:, rubric:, system_prompt:)

        requests = WebMock::RequestRegistry.instance
          .requested_signatures
          .hash
          .keys
          .select { |sig| sig.uri.to_s.include?("chat/completions") }

        expect(requests.length).to eq(2)
      end
    end

    context "with tool calling loop limit" do
      before do
        stub_request(:post, "#{base_url}/chat/completions")
          .to_return(status: 200, body: tool_calls_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "stops after max iterations and returns partial content" do
        result = generator.generate(topic:, rubric:, system_prompt:)

        expect(result[:tool_calls_log].length).to be <= described_class::MAX_TOOL_ITERATIONS
      end
    end
  end

  describe "#generate_streaming" do
    let(:sse_body) do
      [
        "data: #{{ choices: [{ delta: { content: "Нефть " } }] }.to_json}\n\n",
        "data: #{{ choices: [{ delta: { content: "подорожала" } }] }.to_json}\n\n",
        "data: [DONE]\n\n"
      ].join
    end

    before do
      stub_request(:post, "#{base_url}/chat/completions")
        .to_return(status: 200, body: sse_body, headers: { "Content-Type" => "text/event-stream" })
    end

    it "yields text chunks" do
      chunks = []
      generator.generate_streaming(topic:, rubric:, system_prompt:) { |chunk| chunks << chunk }

      expect(chunks).to eq(["Нефть ", "подорожала"])
    end
  end
end
