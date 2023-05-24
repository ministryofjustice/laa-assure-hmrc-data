class BulkSubmission < ApplicationRecord
  include StatusSettable

  belongs_to :user
  has_many :submissions, dependent: :destroy

  has_many :unfinished_submissions,
            -> { where.not(status: %w[completed failed exhausted]) },
            class_name: "Submission"

  has_one_attached :original_file
  has_one_attached :result_file

  has_status :pending,
             :preparing,
             :prepared,
             :processing,
             :completed,
             :writing,
             :ready

  # TODO: this should be doable in a single query
  def finished?
    submissions.count.positive? &&
      unfinished_submissions.count.zero?
  end
end
