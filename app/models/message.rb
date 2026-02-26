class Message < ApplicationRecord
  ROLES = %w[system user assistant tool].freeze

  belongs_to :conversation

  validates :role, presence: true, inclusion: { in: ROLES }
end
