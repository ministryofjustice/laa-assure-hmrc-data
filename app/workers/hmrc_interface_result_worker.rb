class HmrcInterfaceResultWorker < HmrcInterfaceBaseWorker
  sidekiq_retries_exhausted do |job, _ex|
    submission = Submission.find(job['args']&.first)
    submission.exhausted!

    Sentry.capture_message <<~ERROR
      "Failed #{job['class']} for submission #{job['args']}: #{job['error_message']} - status marked as "exhausted""
    ERROR
  end

  def perform(submission_id)
    HmrcInterfaceResultService.call(submission_id)
    super
  end
end
