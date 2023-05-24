class BulkSubmissionStatusWorker < ApplicationWorker
  sidekiq_options queue: DefaultQueueNameService.call

  def perform(bulk_submission_id)
    bulk_submission = BulkSubmission.find(bulk_submission_id)

    if bulk_submission.finished?
      bulk_submission.completed!
      BulkSubmissionResultWriterWorker.perform_async(bulk_submission.id)
    else
      raise TryAgain, "waiting for bulk_submission with id #{bulk_submission.id} to complete..."
    end

    super
  end
end
