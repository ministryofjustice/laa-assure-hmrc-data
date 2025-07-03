class BulkSubmission < ApplicationRecord
  include StatusSettable
  include Discard::Model

  after_discard do
    submissions.discard_all
  end

  after_undiscard do
    submissions.undiscard_all
  end

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
             :exhausted,
             :ready

  def finished?
    submissions.any? &&
      unfinished_submissions.none?
  end
end
