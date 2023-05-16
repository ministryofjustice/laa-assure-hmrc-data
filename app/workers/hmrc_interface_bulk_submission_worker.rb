class HmrcInterfaceBulkSubmissionWorker < ApplicationWorker
  def perform(bulk_submission_id)
    bulk_submission = BulkSubmission.find(bulk_submission_id)
    pending_submissions = bulk_submission.submissions.where(status: 'pending')

    bulk_submission.update!(status: "processing")

    pending_submissions.each do |submission|
      queue = SubmissionQueueNameService.call(submission.use_case)
      HmrcInterfaceSubmissionWorker.set(queue:).perform_async(submission.id)
    end

    super
  end
end
