class BulkSubmissionWorker < ApplicationWorker
  def perform(bulk_submission_id)
    bulk_submission = BulkSubmission.find(bulk_submission_id)
    BulkSubmissionService.call(bulk_submission)

    # TESTING only
    # TODO: this is where we could check for bulk submission process completion and kick of
    # file generation
    # BulkSubmissionMonitoringWorker.perform_async(bulk_submission_id)
    super
  end
end
