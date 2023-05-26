class BulkSubmissionWorker < ApplicationWorker
  sidekiq_options queue: DefaultQueueNameService.call

  def perform(bulk_submission_id)
    bulk_submission = BulkSubmission.find(bulk_submission_id)
    BulkSubmissionService.call(bulk_submission)
    super
  end
end
