class BulkSubmissionResultWriterWorker < ApplicationWorker
  sidekiq_options queue: DefaultQueueNameService.call

  def perform(bulk_submission_id)
    BulkSubmissionResultWriterService.call(bulk_submission_id)
    super
  end
end
