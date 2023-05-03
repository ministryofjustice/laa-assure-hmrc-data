require 'hmrc_interface/configuration'
require 'hmrc_interface/client'

module HmrcInterface
  class << self
    def client
      Client.new
    end

    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end
    alias_method :config, :configuration

    def configure
      yield(configuration) if block_given?
      configuration
    end

    def reset
      @configuration = Configuration.new
    end
  end
end
