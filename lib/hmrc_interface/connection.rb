# frozen_string_literal: true

require "forwardable"

module HmrcInterface
  class Connection
    extend Forwardable
    def_delegator HmrcInterface, :configuration

    attr_reader :connection
    def_delegators :connection, :post, :get

    def initialize(client)
      @connection =
        Faraday.new(url: configuration.host, headers: client.headers)
    end
  end
end
