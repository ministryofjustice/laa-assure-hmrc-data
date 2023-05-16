class HmrcInterfaceResultService
  attr_reader :submission

  def self.call(*args)
    new(*args).call
  end

  def initialize(submission_id)
    @submission = Submission.find(submission_id)
  end

  def call
    submission.update!(status: "completing")

    response = HmrcInterface::Request::Result.call(client, submission.hmrc_interface_id)

    submission.update!(hmrc_interface_result: response, status: response[:status],)

    # seems to be an intermediary step where status can be created
    if %w[processing created].include?(response[:status])
      raise HmrcInterface::TryAgain,
              "still processing submission: #{submission.id} with hmrc interface id #{submission.hmrc_interface_id}"
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
end

