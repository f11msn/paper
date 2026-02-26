class Conversation < ApplicationRecord
  has_many :messages, dependent: :destroy

  validates :title, presence: true
  validates :system_prompt, presence: true
end
