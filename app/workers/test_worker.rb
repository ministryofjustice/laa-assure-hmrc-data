 # :nocov:
class TestWorker
  include Sidekiq::Worker

  sidekiq_options queue: QueueNameService.call, retry: 3

  def perform
    Rails.logger.info "#{Time.current} Starting testworker perform"
  end
end
 # :nocov:
