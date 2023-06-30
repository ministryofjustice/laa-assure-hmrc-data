class BulkSubmission < ApplicationRecord
  include StatusSettable
  include Discard::Model

  after_discard { submissions.discard_all }

  after_undiscard { submissions.undiscard_all }

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
    submissions.count.positive? && unfinished_submissions.count.zero?
  end
end
