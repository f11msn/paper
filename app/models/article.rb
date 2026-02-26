class Article < ApplicationRecord
  RUBRICS = %w[Экономика Политика Бизнес Финансы Общество].freeze
  STATUSES = %w[pending generating completed failed].freeze

  validates :topic, presence: true
  validates :rubric, presence: true, inclusion: { in: RUBRICS }
  validates :status, inclusion: { in: STATUSES }
end
