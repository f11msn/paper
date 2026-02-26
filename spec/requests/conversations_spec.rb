require "rails_helper"

RSpec.describe "Conversations", type: :request do
  describe "GET /conversations" do
    it "returns success" do
      get conversations_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /conversations/new" do
    it "returns success" do
      get new_conversation_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /conversations" do
    it "creates a conversation with system message" do
      post conversations_path, params: {
        conversation: { title: "Тестовый чат", system_prompt: "Ты редактор" }
      }

      conversation = Conversation.last
      expect(response).to redirect_to(conversation_path(conversation))
      expect(conversation.messages.first.role).to eq("system")
      expect(conversation.messages.first.content).to eq("Ты редактор")
    end
  end

  describe "GET /conversations/:id" do
    let!(:conversation) { create(:conversation) }

    it "returns success" do
      get conversation_path(conversation)
      expect(response).to have_http_status(:ok)
    end

    it "shows the debug panel" do
      get conversation_path(conversation)
      expect(response.body).to include("Debug Panel")
      expect(response.body).to include("Messages Array")
    end
  end

  describe "POST /conversations/:id/messages" do
    let!(:conversation) { create(:conversation) }
    let(:chat_response) do
      {
        choices: [
          { message: { role: "assistant", content: "Ответ редактора" }, finish_reason: "stop" }
        ]
      }
    end

    before do
      stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
        .to_return(status: 200, body: chat_response.to_json, headers: { "Content-Type" => "application/json" })

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("OPENROUTER_API_KEY").and_return("test-key")
    end

    it "creates user and assistant messages" do
      expect {
        post conversation_messages_path(conversation), params: {
          message: { content: "Привет!" }
        }
      }.to change(Message, :count).by(2)

      messages = conversation.messages.order(:created_at).last(2)
      expect(messages.first.role).to eq("user")
      expect(messages.first.content).to eq("Привет!")
      expect(messages.last.role).to eq("assistant")
      expect(messages.last.content).to eq("Ответ редактора")
    end
  end

  describe "DELETE /conversations/:id" do
    let!(:conversation) { create(:conversation) }

    it "deletes the conversation" do
      expect {
        delete conversation_path(conversation)
      }.to change(Conversation, :count).by(-1)
    end
  end
end
