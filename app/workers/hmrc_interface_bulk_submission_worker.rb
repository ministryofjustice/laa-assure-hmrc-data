class HmrcInterfaceBulkSubmissionWorker < ApplicationWorker
  sidekiq_options queue: DefaultQueueNameService.call

  def perform(bulk_submission_id)
    bulk_submission = BulkSubmission.find(bulk_submission_id)
    pending_submissions = bulk_submission.submissions.where(status: 'pending')

    bulk_submission.processing!

    pending_submissions.each_with_index do |submission, idx|
      queue = SubmissionQueueNameService.call(submission.use_case)
      HmrcInterfaceSubmissionWorker.set(queue:).perform_async(submission.id, idx)
    end

    super
  end
end
