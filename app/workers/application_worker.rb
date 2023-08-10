require 'sidekiq-scheduler'

class ApplicationWorker
  include Sidekiq::Worker
  extend WorkerErrors

  def perform(*args)
    Rails.logger.info "[#{Time.current.iso8601}] ran #{self.class} with args: #{args}"
  end
end
