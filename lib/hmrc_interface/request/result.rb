require 'hmrc_interface/request/base'

module HmrcInterface
  module Request
    class Result < Base
      attr_reader :submission_id

      def self.call(client, submission_id)
        new(client, submission_id).call
      end

      def initialize(client, submission_id)
        @submission_id = submission_id
        super(client)
      end

      def call
        response = request
        parsed_response = parse_json_response(response.body)

        case response.status
        when 200, 202
          parsed_response
        else
          raise RequestUnacceptable, detailed_error(response.env.url,
                                                    response.status,
                                                    parsed_response)
        end
      end

    private

      def request
        conn.get(url_path)
      rescue StandardError => e
        handle_request_error(e)
      end

      def url_path
        @url_path ||= "api/v1/submission/result/#{submission_id}"
      end
    end
  end
end
