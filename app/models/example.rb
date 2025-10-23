class Example < ApplicationRecord
  # Enum-based status field (common pattern)
  STATUSES = %w[new in_progress completed archived].freeze
  CATEGORIES = %w[ui_pattern backend_pattern data_pattern deployment_pattern].freeze

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :category, inclusion: { in: CATEGORIES }, allow_nil: true
  validates :priority, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }, allow_nil: true
  validates :score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :complexity, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }, allow_nil: true
  validates :speed, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }, allow_nil: true
  validates :quality, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }, allow_nil: true

  # Calculated aggregate (common pattern from idea_tracker)
  def average_metrics
    metrics = [complexity, speed, quality].compact
    return nil if metrics.empty?
    (metrics.sum / metrics.length.to_f).round(1)
  end

  # Status helpers
  def new?
    status == 'new'
  end

  def completed?
    status == 'completed'
  end
end
