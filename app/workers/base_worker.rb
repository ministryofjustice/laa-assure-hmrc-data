require 'sidekiq-scheduler'

class BaseWorker
  include Sidekiq::Worker

  def perform
    # TODO: AP-4043 process HMRC requests from uploaded file
  end
end
