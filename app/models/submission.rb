class Submission < ApplicationRecord
  include StatusSettable

  belongs_to :bulk_submission

  has_status :pending,
             :submitting,
             :submitted,
             :completing,
             :created,
             :processing,
             :completed,
             :failed,
             :exhausted,
             :purged

  USE_CASES = %w[one two].freeze
  NINO_REGEXP = /\A(?!BG)(?!GB)(?!NK)(?!KN)(?!TN)(?!NT)(?!ZZ)[A-CEGHJ-PR-TW-Z][A-CEGHJ-NPR-TW-Z][0-9]{6}([A-DFM])\Z/

  validates :first_name, :last_name, presence: true
  validates :use_case, presence: true, inclusion: { in: USE_CASES }
  validates :nino, presence: true, format: { with: NINO_REGEXP, message: :invalid_format }

  validates :period_start_at, :period_end_at, not_in_future: true
  validate :period_end_after_period_start

  scope :finished, -> { where(status: %w[completed failed exhausted]) }

private

  def period_end_after_period_start
    return if period_end_at.blank? || period_start_at.blank?

    errors.add(:period_start_at, :invalid_period) if period_end_at < period_start_at
    errors.add(:period_end_at, :invalid_period) if period_end_at < period_start_at
  end
end
