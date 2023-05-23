class HmrcInterfaceSubmissionService
  attr_reader :submission, :requestor

  def self.call(*args)
    new(*args).call
  end

  def initialize(submission_id, requestor = HmrcInterface::Request::Submission)
    @submission = Submission.find(submission_id)
    @requestor = requestor
  end

  def call
    submission.update!(status: "submitting")

    response = requestor.call(client, use_case, filter)

    if response[:id].present?
      submission.update!(hmrc_interface_id: response[:id], status: "submitted")
      HmrcInterfaceResultWorker.set(queue:).perform_in(10.seconds, submission.id)
    end
  end

  private

  def client
    @client ||= HmrcInterface.client
  end

  def use_case
    @use_case ||= submission.use_case
  end

  def filter
    @filter ||= {
      nino: submission.nino,
      start_date: submission.period_start_at,
      end_date: submission.period_end_at,
      first_name: submission.first_name,
      last_name: submission.last_name,
      dob: submission.dob,
    }
  end

  def queue
    @queue ||= SubmissionQueueNameService.call(submission.use_case)
  end
end
