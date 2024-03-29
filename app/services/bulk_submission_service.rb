class BulkSubmissionService
  attr_reader :bulk_submission, :parser

  def self.call(*)
    new(*).call
  end

  def initialize(bulk_submission, parser = BulkSubmissionCsvParser)
    @bulk_submission = bulk_submission
    @parser = parser
  end

  def call
    bulk_submission.preparing!

    file_records.each do |rec|
      create_submission!(use_case: :one, submission: rec)
      create_submission!(use_case: :two, submission: rec)
    end

    bulk_submission.prepared!

    HmrcInterfaceBulkSubmissionWorker.perform_async(bulk_submission.id)
    BulkSubmissionStatusWorker.perform_in(delay.seconds, bulk_submission.id)
  end

private

  def create_submission!(use_case:, submission:)
    Submission.create!(
        use_case:,
        bulk_submission_id: bulk_submission.id,
        period_start_at: submission.period_start_at,
        period_end_at: submission.period_end_at,
        first_name: submission.first_name,
        last_name: submission.last_name,
        dob: submission.dob,
        nino: submission.nino,
        status: :pending,
    )
  rescue Date::Error, ActiveRecord::RecordInvalid => e
    Rails.logger.error(e.message)
  end

  def file_records
    @file_records ||= parser.call(file_contents)
  end

  def file_contents
    @file_contents ||= bulk_submission.original_file.download
  end

  # approx 7 seconds for HMRC interface to return a result for an existing person
  def delay
    bulk_submission.submissions.count * 7
  end
end
