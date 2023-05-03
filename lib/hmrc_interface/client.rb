require 'forwardable'

module HmrcInterface
  class Client
    delegate :configuration, to: HmrcInterface
    delegate :host, to: :configuration

    attr_reader :connection

    def initialize
      oauth_client
      @connection = Connection.new(self)
    end

     def headers
      configuration.headers.merge(
        {
          "Content-Type" => "application/json",
          "Accept" => "application/json",
          "Authorization" => "Bearer #{bearer_token}",
        }
      )
    end

    def bearer_token
      configuration.test_mode? ? fake_bearer_token : access_token.token
    end

    def access_token
      @access_token = new_access_token if @access_token.nil? || @access_token.expired?
      @access_token
    end

private

    def oauth_client
      @oauth_client ||= ::OAuth2::Client.new(
        configuration.client_id,
        configuration.client_secret,
        site: configuration.host,
      )
    end

    def new_access_token
      oauth_client.client_credentials.get_token
    end

    def fake_bearer_token
      "fake-hmrc-interface-bearer-token"
    end
  end
end
