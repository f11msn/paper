FactoryBot.define do
  factory :message do
    conversation
    role { "user" }
    content { "Привет" }
  end
end
