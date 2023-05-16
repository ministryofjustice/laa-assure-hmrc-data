class HmrcInterfaceResultWorker < HmrcInterfaceBaseWorker
  def perform(submission_id)
    HmrcInterfaceResultService.call(submission_id)
    super
  end
end
