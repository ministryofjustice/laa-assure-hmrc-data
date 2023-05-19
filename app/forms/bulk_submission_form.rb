class BulkSubmissionForm
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks

  MAX_FILE_SIZE = 1.megabyte

  ALLOWED_CONTENT_TYPES = %w[
    text/csv
  ].freeze

  attr_accessor :bulk_submission,
                :uploaded_file,
                :user_id,
                :status

  validate :file_chosen,
           :file_empty,
           :file_too_big,
           :file_content_type

  def self.max_file_size
    MAX_FILE_SIZE
  end

  def save
    validate
    return false unless valid?

    self.bulk_submission = BulkSubmission.new(user_id:, status:)
    bulk_submission.original_file.attach(uploaded_file)
    bulk_submission.save!
  end

  def update
    validate
    return false unless valid?

    bulk_submission.original_file.attach(uploaded_file)
  end

private

  def file_chosen
    return if uploaded_file || bulk_submission&.original_file&.attached?

    errors.add(:uploaded_file, :blank)
  end

  def file_empty
    return unless uploaded_file
    return if file_size(uploaded_file) > 1

    errors.add(:uploaded_file, :file_empty, filename: uploaded_file.original_filename)
  end

  def file_too_big
    return unless uploaded_file
    return if file_size(uploaded_file) <= self.class.max_file_size

    error_options = { size: self.class.max_file_size / 1.megabyte, filename: uploaded_file.original_filename }
    errors.add(:uploaded_file, :file_too_big, **error_options)
  end

  def file_content_type
    return unless uploaded_file
    return if [checked_content_type(uploaded_file), uploaded_file.content_type].compact_blank.all? do |mime_type|
      mime_type.in?(ALLOWED_CONTENT_TYPES)
    end

    errors.add(:uploaded_file, :content_type_invalid, filename: uploaded_file.original_filename)
  end

  def checked_content_type(file)
    Marcel::Magic.by_magic(file)&.type
  end

  def file_size(file)
    return 0 if file.nil?
    File.size(file&.tempfile)
  end
end
