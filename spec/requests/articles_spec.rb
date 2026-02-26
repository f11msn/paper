require "rails_helper"

RSpec.describe "Articles", type: :request do
  describe "GET /articles" do
    it "returns success" do
      get articles_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /articles/new" do
    it "returns success" do
      get new_article_path
      expect(response).to have_http_status(:ok)
    end

    it "contains the form with system prompt" do
      get new_article_path
      expect(response.body).to include("System Message")
      expect(response.body).to include("Temperature")
    end
  end

  describe "POST /articles" do
    let(:chat_response) do
      {
        choices: [
          { message: { role: "assistant", content: "Тестовая статья" }, finish_reason: "stop" }
        ]
      }
    end

    before do
      stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
        .to_return(status: 200, body: chat_response.to_json, headers: { "Content-Type" => "application/json" })

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("OPENROUTER_API_KEY").and_return("test-key")
    end

    it "creates an article and redirects" do
      post articles_path, params: {
        article: {
          topic: "Тест",
          rubric: "Экономика",
          system_prompt: "Ты журналист",
          temperature: 0.7,
          max_tokens: 1000,
          model: "deepseek/deepseek-v3.2"
        }
      }

      expect(response).to redirect_to(article_path(Article.last))
      expect(Article.last.status).to eq("completed")
    end
  end

  describe "GET /articles/:id" do
    let!(:article) { create(:article, content: "Текст статьи", status: "completed") }

    it "returns success" do
      get article_path(article)
      expect(response).to have_http_status(:ok)
    end

    it "shows the article content" do
      get article_path(article)
      expect(response.body).to include("Текст статьи")
    end

    it "shows the debug panel" do
      get article_path(article)
      expect(response.body).to include("Debug Panel")
    end

    it "shows the retry button" do
      get article_path(article)
      expect(response.body).to include("Сгенерировать заново")
    end
  end

  describe "POST /articles/:id/retry" do
    let!(:article) { create(:article, content: "Старый текст", status: "failed") }

    let(:chat_response) do
      {
        choices: [
          { message: { role: "assistant", content: "Новая статья" }, finish_reason: "stop" }
        ]
      }
    end

    before do
      stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
        .to_return(status: 200, body: chat_response.to_json, headers: { "Content-Type" => "application/json" })

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("OPENROUTER_API_KEY").and_return("test-key")
    end

    it "regenerates the article and redirects" do
      post retry_article_path(article)

      expect(response).to redirect_to(article_path(article))
      article.reload
      expect(article.status).to eq("completed")
      expect(article.content).to eq("Новая статья")
    end
  end
end
