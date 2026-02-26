class ConversationsController < ApplicationController
  def index
    @conversations = Conversation.order(created_at: :desc)
  end

  def show
    @conversation = Conversation.find(params[:id])
    @messages = @conversation.messages.order(:created_at)
    @new_message = Message.new
  end

  def new
    @conversation = Conversation.new(
      system_prompt: ArticleGenerator::DEFAULT_SYSTEM_PROMPT
    )
  end

  def create
    @conversation = Conversation.new(conversation_params)

    if @conversation.save
      @conversation.messages.create!(role: "system", content: @conversation.system_prompt)
      redirect_to @conversation
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @conversation = Conversation.find(params[:id])
    @conversation.destroy
    redirect_to conversations_path, notice: "Чат удалён"
  end

  private

  def conversation_params
    params.require(:conversation).permit(:title, :system_prompt)
  end
end
