require 'forwardable'

module HmrcInterface
  class Client
    extend Forwardable
    def_delegator HmrcInterface, :configuration

    def initialize
      oauth_client
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
