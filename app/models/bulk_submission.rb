class BulkSubmission < ApplicationRecord
  include StatusSettable

  belongs_to :user
  has_many :submissions, dependent: :destroy
  has_one_attached :original_file
  has_status :pending, :preparing, :prepared, :processing, :completed
end
