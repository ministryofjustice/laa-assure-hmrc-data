require "hmrc_interface/error_helper"

module HmrcInterface
  module Request
    class Base
      include HmrcInterface::ErrorHelper

      attr_reader :client
      delegate :host, :connection, :headers, to: :client

      def initialize(client)
        @client = client
      end

      private

      def parse_json_response(response_body)
        JSON.parse(response_body, symbolize_names: true)
      rescue JSON::ParserError, TypeError
        response_body || ""
      end
    end
  end
end
