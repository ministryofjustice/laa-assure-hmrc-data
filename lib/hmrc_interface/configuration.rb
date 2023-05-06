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

    def logger
      @logger ||= defined?(Rails) ? Rails.logger : Logger.new($stdout)
    end

    def logger=(logger)
      if has_required_logger_methods?(logger)
        @logger = logger
      else
        raise ConfigurationError, "configured logger must respond to #{required_logger_methods.join(', ')}"
      end
    end

    def test_mode?
      test_mode.to_s == "true"
    end

  private

    def user_agent_header
      { 'User-Agent' => "laa-hmrc-interface-client/#{VERSION}" }
    end

    def has_required_logger_methods?(logger)
      (required_logger_methods & logger.methods) == required_logger_methods
    end

    def required_logger_methods
      %i[info warn error fatal debug]
    end
  end
end
