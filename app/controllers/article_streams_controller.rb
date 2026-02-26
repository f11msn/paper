class ArticleStreamsController < ApplicationController
  include ActionController::Live

  def show
    @article = Article.find(params[:article_id])

    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    client = OpenaiClient.new(
      api_key: ENV.fetch("OPENROUTER_API_KEY"),
      model: @article.model
    )
    generator = ArticleGenerator.new(client:)

    full_content = +""

    generator.generate_streaming(
      topic: @article.topic,
      rubric: @article.rubric,
      system_prompt: @article.system_prompt,
      temperature: @article.temperature,
      max_tokens: @article.max_tokens
    ) do |chunk|
      full_content << chunk
      response.stream.write("data: #{chunk.to_json}\n\n")
    end

    response.stream.write("data: [DONE]\n\n")

    @article.update!(content: full_content, status: "completed")
  rescue ActionController::Live::ClientDisconnected, IOError
    # Client disconnected
  ensure
    response.stream.close
  end
end
