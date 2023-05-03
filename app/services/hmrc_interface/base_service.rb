require 'hmrc_interface/error_helper'

module HmrcInterface
  class BaseService
    include HmrcInterface::ErrorHelper

    attr_reader :client, :submission
    delegate :host, :connection, :headers, to: :client

    def self.call(client, submission)
      new(client, submission).call
    end

    def initialize(client, submission)
      @client = client
      @submission = submission
    end

  private

    def parse_json_response(response_body)
      JSON.parse(response_body, symbolize_names: true)
    rescue JSON::ParserError, TypeError
      response_body || ""
    end
  end
end
