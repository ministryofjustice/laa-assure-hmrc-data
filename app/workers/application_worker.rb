require 'sidekiq-scheduler'

class ApplicationWorker
  include Sidekiq::Worker

  class TryAgain < StandardError
    def initialize(message = "still processing...")
      super(message)
    end
  end

  def perform(*args)
    Rails.logger.info "[#{Time.current}] ran #{self.class} with args: #{args}"
  end
end
