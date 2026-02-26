require "rails_helper"

RSpec.describe ToolExecutor do
  describe ".tools_schema" do
    it "returns an array of 3 tool definitions" do
      schema = described_class.tools_schema

      expect(schema).to be_an(Array)
      expect(schema.length).to eq(3)
    end

    it "follows OpenAI tool format" do
      schema = described_class.tools_schema

      schema.each do |tool|
        expect(tool[:type]).to eq("function")
        expect(tool[:function]).to include(:name, :description, :parameters)
        expect(tool[:function][:parameters][:type]).to eq("object")
      end
    end

    it "includes search_news, get_quote, get_statistics" do
      names = described_class.tools_schema.map { |t| t[:function][:name] }

      expect(names).to contain_exactly("search_news", "get_quote", "get_statistics")
    end
  end

  describe ".execute" do
    it "executes search_news and returns JSON string" do
      result = described_class.execute(function_name: "search_news", arguments: { "query" => "нефть" })

      parsed = JSON.parse(result)
      expect(parsed).to have_key("results")
      expect(parsed["results"]).to be_an(Array)
      expect(parsed["results"]).not_to be_empty
    end

    it "executes get_quote and returns JSON string" do
      result = described_class.execute(function_name: "get_quote", arguments: { "person" => "Иванов", "topic" => "экономика" })

      parsed = JSON.parse(result)
      expect(parsed).to have_key("quote")
      expect(parsed).to have_key("person")
    end

    it "executes get_statistics and returns JSON string" do
      result = described_class.execute(function_name: "get_statistics", arguments: { "topic" => "нефть" })

      parsed = JSON.parse(result)
      expect(parsed).to have_key("statistics")
      expect(parsed["statistics"]).to be_an(Array)
    end

    it "raises on unknown function" do
      expect {
        described_class.execute(function_name: "unknown_func", arguments: {})
      }.to raise_error(ToolExecutor::UnknownToolError)
    end
  end
end
