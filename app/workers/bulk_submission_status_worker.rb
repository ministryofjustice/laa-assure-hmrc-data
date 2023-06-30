class BulkSubmissionStatusWorker < ApplicationWorker
  sidekiq_options retry: 6 # ~19m 34s total
  sidekiq_options queue: DefaultQueueNameService.call

  sidekiq_retries_exhausted do |job, _ex|
    bulk_submission = BulkSubmission.find(job["args"]&.first)
    bulk_submission.exhausted!

    Sentry.capture_message <<~ERROR
      "Failed #{job["class"]} for bulk_submission #{job["args"]}: #{job["error_message"]} - status marked as \"exhausted\""
    ERROR
  end

  def perform(bulk_submission_id)
    bulk_submission = BulkSubmission.find(bulk_submission_id)

    if bulk_submission.finished?
      bulk_submission.completed!
      BulkSubmissionResultWriterWorker.perform_async(bulk_submission.id)
    else
      raise WorkerErrors::TryAgain,
            "waiting for bulk_submission with id #{bulk_submission.id} to complete..."
    end

    super
  end
end
