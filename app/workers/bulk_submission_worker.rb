class BulkSubmissionWorker < ApplicationWorker
  sidekiq_options queue: DefaultQueueNameService.call

  def perform(bulk_submission_id)
    bulk_submission = BulkSubmission.find(bulk_submission_id)
    BulkSubmissionService.call(bulk_submission)

    # TODO: this is where we could check for bulk submission process completion and kick of file generation
    super
  end
end
