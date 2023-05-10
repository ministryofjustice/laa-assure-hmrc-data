 # :nocov:
class TestWorker
  include Sidekiq::Worker

  sidekiq_options queue: "uc-one-#{QueueNameService.call}", retry: 3

  def perform
    Rails.logger.info "#{Time.current} Starting testworker perform"
  end
end
 # :nocov:
