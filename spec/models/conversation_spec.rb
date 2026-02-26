require "rails_helper"

RSpec.describe Conversation, type: :model do
  it "is valid with title and system_prompt" do
    conversation = build(:conversation)
    expect(conversation).to be_valid
  end

  it "is invalid without title" do
    conversation = build(:conversation, title: nil)
    expect(conversation).not_to be_valid
  end

  it "destroys messages on deletion" do
    conversation = create(:conversation)
    create(:message, conversation:)
    expect { conversation.destroy }.to change(Message, :count).by(-1)
  end
end
