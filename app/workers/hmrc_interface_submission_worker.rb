class HmrcInterfaceSubmissionWorker < HmrcInterfaceBaseWorker
  def perform(submission_id, idx)
    HmrcInterfaceSubmissionService.call(submission_id, idx)
    super
  end
end
