class BulkSubmissionsWorker < ApplicationWorker
  sidekiq_options queue: DefaultQueueNameService.call

  def perform
    pending_bulk_submissions_ids = BulkSubmission.where(status: 'pending').ids

    pending_bulk_submissions_ids.each do |bulk_submission_id|
      queue = DefaultQueueNameService.call
      BulkSubmissionWorker.set(queue:).perform_async(bulk_submission_id)
    end
    super
  end
end
