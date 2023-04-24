class BulkSubmission < ApplicationRecord
  belongs_to :user
  has_one_attached :original_file
end
