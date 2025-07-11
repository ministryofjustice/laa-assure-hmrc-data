require "csv"

class BulkSubmissionForm
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks
  include MalwareScanning

  MAX_FILE_SIZE = 1.megabyte
  DATE_FORMAT = "%Y-%m-%d".freeze

  ALLOWED_CONTENT_TYPES = %w[
    text/csv
  ].freeze

  EXPECTED_HEADERS = %w[
    period_start_date
    period_end_date
    first_name
    last_name
    date_of_birth
    nino
].freeze

  attr_accessor :bulk_submission,
                :uploaded_file,
                :user_id,
                :status

  validate :file_chosen,
           :file_empty,
           :file_too_big,
           :file_content_type,
           :file_contains_virus

  validate :file_content, if: proc { errors.empty? }

  def self.max_file_size
    MAX_FILE_SIZE
  end

  def save
    return false unless valid?

    self.bulk_submission = BulkSubmission.new(user_id:, status:)
    bulk_submission.original_file.attach(uploaded_file)
    bulk_submission.save!
  end

  def update
    return false unless valid?

    bulk_submission.original_file.attach(uploaded_file)
  end

private

  def file_contains_virus
    return unless uploaded_file && file_scan.virus_found?

    errors.add(:uploaded_file, :file_contains_virus, filename: uploaded_file.original_filename)
  end

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

  def file_scan
    @file_scan ||= malware_scan_result(uploaded_file)
  end

  def uploader
    @uploader ||= User.find(user_id)
  end

  def file_size(file)
    return 0 if file.nil?
    File.size(file&.tempfile)
  end

  def csv
    @csv ||= CSV.parse(
      File.read(uploaded_file),
      headers: :first_row,
      header_converters: lambda { |f| f.strip },
      converters: lambda { |f| f ? f.strip : nil }
    )
  rescue StandardError
    errors.add(:uploaded_file, :unparseable_file, filename: uploaded_file.original_filename)
    nil
  end

  def file_content
    return unless uploaded_file && csv && row_count_acceptable?

    validate_headers
    validate_first_names
    validate_last_names
    validate_ninos
    validate_dobs
    validate_period_start_dates
    validate_period_end_dates
  end

  def row_count_acceptable?
    return true if csv.size < 36

    errors.add(:uploaded_file, :file_too_long, filename: uploaded_file.original_filename)
    false
  end

  def validate_headers
    errors.add(:uploaded_file,
               :invalid_headers,
               filename: uploaded_file.original_filename) unless csv.headers == EXPECTED_HEADERS
  end

  def validate_first_names
    csv.by_col["first_name"].each_with_index do |first_name, index|
      errors.add(:uploaded_file,
                 :missing_first_name,
                 filename: uploaded_file.original_filename,
                 row_num: index+2) if first_name.blank?
    end
  end

  def validate_last_names
    csv.by_col["last_name"].each_with_index do |last_name, index|
      errors.add(:uploaded_file,
                 :missing_last_name,
                 filename: uploaded_file.original_filename,
                 row_num: index+2) if last_name.blank?
    end
  end

  def validate_ninos
    csv.by_col["nino"].each_with_index do |nino, index|
      errors.add(:uploaded_file,
                 :invalid_nino,
                 filename: uploaded_file.original_filename,
                 row_num: index+2) unless Submission::NINO_REGEXP.match? nino
    end
  end

  def validate_dobs
    csv.by_col["date_of_birth"].each_with_index do |dob, index|
      errors.add(:uploaded_file,
                 :invalid_dob,
                 filename: uploaded_file.original_filename,
                 row_num: index+2) unless valid_date?(parse_date(dob))
    end
  end

  def validate_period_start_dates
    csv.by_col["period_start_date"].each_with_index do |start_date, index|
      errors.add(:uploaded_file,
                 :invalid_period_start_date,
                 filename: uploaded_file.original_filename,
                 row_num: index+2) unless valid_date?(parse_date(start_date))
    end
  end

  def validate_period_end_dates
    csv.by_col["period_end_date"].each_with_index do |end_date, index|
      parsed_end_date = parse_date(end_date)
      parsed_start_date = parse_date(csv[index]["period_start_date"])

      if !valid_date?(parsed_end_date)
        errors.add(:uploaded_file,
                   :invalid_period_end_date,
                   filename: uploaded_file.original_filename,
                   row_num: index + 2)
      elsif valid_date?(parsed_start_date) && (parsed_end_date < parsed_start_date)
        errors.add(:uploaded_file,
                   :period_end_date_before_start_date,
                   filename: uploaded_file.original_filename,
                   row_num: index + 2)
      end
    end
  end

  def parse_date(date_str)
    Time.strptime(date_str, Time::DATE_FORMATS[:csv])
  rescue StandardError
    nil
  end

  def valid_date?(value)
    return false unless value.is_a?(Time) && value < Date.current

    true
  end
end
