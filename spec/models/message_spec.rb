require "rails_helper"

RSpec.describe Message, type: :model do
  it "is valid with role and conversation" do
    message = build(:message)
    expect(message).to be_valid
  end

  it "is invalid without role" do
    message = build(:message, role: nil)
    expect(message).not_to be_valid
  end

  it "is invalid with unknown role" do
    message = build(:message, role: "moderator")
    expect(message).not_to be_valid
    expect(message.errors[:role]).to include("is not included in the list")
  end

  it "accepts all valid roles" do
    %w[system user assistant tool].each do |role|
      message = build(:message, role:)
      expect(message).to be_valid, "Expected role '#{role}' to be valid"
    end
  end

  it "belongs to a conversation" do
    message = create(:message)
    expect(message.conversation).to be_a(Conversation)
  end
end
