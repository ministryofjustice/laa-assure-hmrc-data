class PurgeWorker < ApplicationWorker

  def perform
    bulk_submissions = BulkSubmission.where(expires_at: ..Time.zone.now)
    bulk_submissions.each do |bulk_submission|
      bulk_submission.original_file.purge
      bulk_submission.result_file.purge
      bulk_submission.submissions.each do |submission|
        submission.update!(first_name: 'purged', last_name: 'purged', dob: Date.parse('1970-01-01'), nino: 'AB123456C')
      end
    end

    super
  end
end
