class HmrcInterfaceSubmissionService
  attr_reader :submission, :number_in_queue, :requestor

  def self.call(*)
    new(*).call
  end

  def initialize(submission_id, number_in_queue = 0, requestor = HmrcInterface::Request::Submission)
    @submission = Submission.find(submission_id)
    @number_in_queue = number_in_queue
    @requestor = requestor
  end

  def call
    submission.submitting!

    response = requestor.call(client, use_case, filter)

    if response[:id].present?
      submission.update!(hmrc_interface_id: response[:id], status: "submitted")
      HmrcInterfaceResultWorker.set(queue:).perform_in(delay.seconds, submission.id)
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

  # potentially 7s for HMRC interface to retrieve a result, with upto 35 requests per bulk submission
  def delay
    (number_in_queue + 1) * 7
  end
end
