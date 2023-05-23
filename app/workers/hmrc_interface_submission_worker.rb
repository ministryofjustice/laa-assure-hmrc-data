class HmrcInterfaceSubmissionWorker < HmrcInterfaceBaseWorker
  def perform(submission_id)
    HmrcInterfaceSubmissionService.call(submission_id)
    super
  end
end
