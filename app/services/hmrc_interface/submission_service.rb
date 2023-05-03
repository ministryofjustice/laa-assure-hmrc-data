module HmrcInterface
  class SubmissionService < BaseService
    def call
      response = request
      parsed_response = parse_json_response(response.body)

      if response.status == 202
        parsed_response
      else
        raise HmrcInterface::Unacceptable, detailed_error(response.env.url,
                                                          response.status,
                                                          parsed_response)
      end
    end

    def request_body
      @request_body ||= json_for_hmrc
    end

  private

    # TODO: inject these as `params`??
    def json_for_hmrc
      {
        filter:
          {
            start_date: submission.period_start_at.to_date.iso8601,
            end_date: submission.period_end_at.to_date.iso8601,
            first_name: submission.first_name,
            last_name: submission.last_name,
            dob: submission.dob.to_date.iso8601,
            nino: submission.nino,
          }
      }.to_json
    end

    def request
      connection.post do |request|
        request.url url_path
        request.headers = headers
        request.body = request_body
      end
    rescue StandardError => e
      handle_request_error(e)
    end

    # TODO: move create endpoint string to config?
    def url_path
      @url_path ||= "api/v1/submission/create/#{submission.use_case}"
    end
  end
end
