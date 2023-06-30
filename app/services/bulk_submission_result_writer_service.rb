require "csv"

class BulkSubmissionResultWriterService
  attr_reader :bulk_submission, :original_headers, :result_parser

  def self.call(*args)
    new(*args).call
  end

  def initialize(bulk_submission_id, result_parser = SubmissionResultCsv)
    @bulk_submission = BulkSubmission.find(bulk_submission_id)
    @original_headers = original_headers
    @result_parser = result_parser
  end

  def call
    bulk_submission.writing!
    attach_result
    bulk_submission.update!(expires_at: 1.month.from_now.midnight)
    bulk_submission.ready!
  end

  private

  def attach_result
    bulk_submission.result_file.attach(
      io: StringIO.new(csv_string),
      filename: "#{bulk_submission.original_file.filename.base}-result.csv",
      content_type: "text/csv"
    )
  end

  def csv_string
    CSV.generate(headers: :first_row, force_quotes: true) do |csv|
      csv << result_parser.headers

      bulk_submission
        .submissions
        .where(use_case: :one)
        .each { |submission| csv << result_parser.new(submission).row }
    end
  end
end
