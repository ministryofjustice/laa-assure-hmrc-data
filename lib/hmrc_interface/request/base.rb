require 'hmrc_interface/error_helper'

module HmrcInterface
  module Request
    class Base
      include HmrcInterface::ErrorHelper

      Filter = Struct.new('Filter', :start_date, :end_date, :first_name, :last_name, :dob, :nino)

      attr_reader :client, :use_case, :filter
      delegate :host, :connection, :headers, to: :client

      def self.call(client, use_case, filter = {})
        new(client, use_case, filter).call
      end

      def initialize(client, use_case, filter = {})
        @client = client
        @use_case = use_case
        @filter = Filter.new(**filter)
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
