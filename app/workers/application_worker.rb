require 'sidekiq-scheduler'

class ApplicationWorker
  include Sidekiq::Worker
  extend WorkerErrors

  def perform(*args)
    Rails.logger.info "[#{Time.current}] ran #{self.class} with args: #{args}"
  end
end
