class ArticlesController < ApplicationController
  def index
    @articles = Article.order(created_at: :desc)
  end

  def show
    @article = Article.find(params[:id])
  end

  def new
    @article = Article.new(
      system_prompt: ArticleGenerator::DEFAULT_SYSTEM_PROMPT,
      temperature: 0.7,
      max_tokens: 4096,
      model: OpenaiClient::DEFAULT_MODEL
    )
  end

  def create
    @article = Article.new(article_params)
    @article.status = "generating"

    if @article.save
      respond_to do |format|
        format.json { render json: { id: @article.id } }
        format.html do
          generate_article!(@article)
          redirect_to @article
        end
      end
    else
      respond_to do |format|
        format.json { render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def pdf
    @article = Article.find(params[:id])
    pdf_data = PdfExporter.new(@article).generate

    send_data pdf_data,
      filename: "#{@article.topic.parameterize}.pdf",
      type: "application/pdf",
      disposition: "inline"
  end

  def retry
    @article = Article.find(params[:id])
    @article.update!(status: "generating", content: nil, api_log: nil, tool_calls_log: nil)
    generate_article!(@article)
    redirect_to @article
  end

  private

  def article_params
    params.require(:article).permit(:topic, :rubric, :system_prompt, :temperature, :max_tokens, :model)
  end

  def generate_article!(article)
    client = OpenaiClient.new(
      api_key: ENV.fetch("OPENROUTER_API_KEY"),
      model: article.model
    )
    generator = ArticleGenerator.new(client:)
    result = generator.generate(
      topic: article.topic,
      rubric: article.rubric,
      system_prompt: article.system_prompt,
      temperature: article.temperature,
      max_tokens: article.max_tokens
    )

    article.update!(
      content: result[:content],
      api_log: result[:api_log],
      tool_calls_log: result[:tool_calls_log],
      status: "completed"
    )
  rescue StandardError => e
    article.update!(status: "failed", content: "Ошибка: #{e.message}")
  end
end
