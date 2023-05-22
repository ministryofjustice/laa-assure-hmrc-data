class HmrcInterfaceResultService
  attr_reader :submission

  def self.call(*args)
    new(*args).call
  end

  def initialize(submission_id)
    @submission = Submission.find(submission_id)
  end

  def call
    submission.completing!

    response = HmrcInterface::Request::Result.call(client, submission.hmrc_interface_id)

    submission.update!(hmrc_interface_result: response, status: response[:status])

    # "processing" and "created" statuses require a retry
    unless %w[completed failed].include?(response[:status])
      raise HmrcInterface::TryAgain,
              "still processing submission: #{submission.id} with hmrc interface id #{submission.hmrc_interface_id}"
    end
  end

  private

  def client
    @client ||= HmrcInterface.client
  end
end

