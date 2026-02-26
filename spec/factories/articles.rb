FactoryBot.define do
  factory :article do
    topic { "Рост цен на нефть" }
    rubric { "Экономика" }
    system_prompt { "Ты — журналист Коммерсанта" }
    status { "pending" }
  end
end
