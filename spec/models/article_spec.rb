require "rails_helper"

RSpec.describe Article, type: :model do
  it "is valid with topic and rubric" do
    article = build(:article)
    expect(article).to be_valid
  end

  it "is invalid without topic" do
    article = build(:article, topic: nil)
    expect(article).not_to be_valid
    expect(article.errors[:topic]).to include("can't be blank")
  end

  it "is invalid without rubric" do
    article = build(:article, rubric: nil)
    expect(article).not_to be_valid
  end

  it "is invalid with unknown rubric" do
    article = build(:article, rubric: "Спорт")
    expect(article).not_to be_valid
    expect(article.errors[:rubric]).to include("is not included in the list")
  end

  it "defaults to pending status" do
    article = Article.new(topic: "Test", rubric: "Экономика", system_prompt: "Test")
    expect(article.status).to eq("pending")
  end
end
