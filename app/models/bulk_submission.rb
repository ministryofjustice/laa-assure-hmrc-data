class BulkSubmission < ApplicationRecord
  belongs_to :user
  has_many :submissions, dependent: :destroy
  has_one_attached :original_file
end
