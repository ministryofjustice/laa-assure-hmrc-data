class HmrcInterfaceBulkSubmissionWorker < ApplicationWorker
  sidekiq_options queue: DefaultQueueNameService.call

  # NOTE: ..to self on possible alternative to using sidekiq processes with concurrency of 1
  # and single queue - Sidekiq 7 "capsules" force single threaded or serial execution and could
  # be used for the HmrcInterfaceSubmissionWorker, so we do not overwhelm hmrc interface
  # see https://github.com/sidekiq/sidekiq/wiki/Advanced-Options#capsules

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
