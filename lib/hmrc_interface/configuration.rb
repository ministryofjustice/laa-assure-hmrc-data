# frozen_string_literal: true

module HmrcInterface
  class Configuration
    VERSION = '0.0.1'

    attr_accessor :client_id,
                  :client_secret,
                  :host,
                  :test_mode

    attr_reader :headers

    def initialize
      @headers = user_agent_header
    end

    def headers=(headers)
      @headers.merge!(headers)
    end

    def test_mode?
      test_mode.to_s == "true"
    end

    private

    def user_agent_header
      { 'User-Agent' => "laa-hmrc-interface-client/#{VERSION}" }
    end
  end
end
