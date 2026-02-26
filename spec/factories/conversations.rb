FactoryBot.define do
  factory :conversation do
    title { "Обсуждение статьи" }
    system_prompt { "Ты — редактор Коммерсанта" }
  end
end
