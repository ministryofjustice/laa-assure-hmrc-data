require 'sidekiq-scheduler'

class ApplicationWorker
  include Sidekiq::Worker

  def perform(*args)
    Rails.logger.info "[#{Time.current}] running #{self.class} with args: #{args}"
  end
end
