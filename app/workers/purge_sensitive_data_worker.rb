class PurgeSensitiveDataWorker < ApplicationWorker

  def perform
    bulk_submissions = expired_bulk_submissions.or(purgeable_bulk_submissions)
    bulk_submissions.each do |bulk_submission|
      bulk_submission.original_file.purge
      bulk_submission.result_file.purge
      bulk_submission.submissions.each do |submission|
        submission.update!(first_name: 'purged', last_name: 'purged', dob: Date.parse('1970-01-01'), nino: 'AB123456C', 
hmrc_interface_result: '{}')
      end
    end

    super
  end

private

  def expired_bulk_submissions
    BulkSubmission.where(expires_at: ..Time.current)
  end

  def purgeable_bulk_submissions
    BulkSubmission.where(expires_at: nil, created_at: ..1.month.ago)
  end
end
