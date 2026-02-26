class MessagesController < ApplicationController
  def create
    @conversation = Conversation.find(params[:conversation_id])
    @message = @conversation.messages.create!(role: "user", content: message_params[:content])

    api_messages = @conversation.messages.order(:created_at).map do |msg|
      hash = { role: msg.role, content: msg.content }
      hash[:tool_calls] = msg.tool_calls if msg.tool_calls.present?
      hash[:tool_call_id] = msg.tool_call_id if msg.tool_call_id.present?
      hash
    end

    client = OpenaiClient.new(api_key: ENV.fetch("OPENROUTER_API_KEY"))
    response = client.chat(messages: api_messages)

    assistant_content = response.dig("choices", 0, "message", "content")
    tool_calls = response.dig("choices", 0, "message", "tool_calls")

    @conversation.messages.create!(
      role: "assistant",
      content: assistant_content,
      tool_calls: tool_calls
    )

    redirect_to @conversation
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
