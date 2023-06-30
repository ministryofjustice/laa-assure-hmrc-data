require "hmrc_interface/request/base"

module HmrcInterface
  module Request
    class Submission < Base
      Filter =
        Struct.new(
          "Filter",
          :start_date,
          :end_date,
          :first_name,
          :last_name,
          :dob,
          :nino
        )

      attr_reader :use_case, :filter

      def self.call(client, use_case, filter = {})
        new(client, use_case, filter).call
      end

      def initialize(client, use_case, filter = {})
        @use_case = use_case
        @filter = Filter.new(**filter)
        super(client)
      end

      def call
        response = request
        parsed_response = parse_json_response(response.body)

        if response.status == 202
          parsed_response
        else
          raise RequestUnacceptable,
                detailed_error(
                  response.env.url,
                  response.status,
                  parsed_response
                )
        end
      end

      def request_body
        @request_body ||= filter_json
      end

      private

      def filter_json
        {
          filter: {
            start_date: filter.start_date.to_date.iso8601,
            end_date: filter.end_date.to_date.iso8601,
            first_name: filter.first_name,
            last_name: filter.last_name,
            dob: filter.dob.to_date.iso8601,
            nino: filter.nino
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
        handle_request_error(e, "POST")
      end

      def url_path
        @url_path ||= "api/v1/submission/create/#{use_case}"
      end
    end
  end
end
