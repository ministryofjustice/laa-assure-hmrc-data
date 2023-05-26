class HmrcInterfaceResultService
  extend WorkerErrors
  attr_reader :submission, :requestor

  def self.call(*args)
    new(*args).call
  end

  def initialize(submission_id, requestor = HmrcInterface::Request::Result)
    @submission = Submission.find(submission_id)
    @requestor = requestor
  end

  def call
    submission.completing!

    response = requestor.call(client, submission.hmrc_interface_id)

    submission.update!(hmrc_interface_result: response, status: response[:status])

    # "processing" and "created" statuses require a retry
    unless %w[completed failed].include?(response[:status])
      raise WorkerErrors::TryAgain,
              "still processing submission: #{submission.id} with hmrc interface id #{submission.hmrc_interface_id}"
    end
  end

  private

  def client
    @client ||= HmrcInterface.client
  end
end

