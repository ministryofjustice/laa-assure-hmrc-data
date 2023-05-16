# see https://github.com/sidekiq/sidekiq/wiki/Error-Handling#configuration
#
class HmrcInterfaceBaseWorker < ApplicationWorker
  sidekiq_options retry: 10

  # overrides the default interval algorithm between retries
  # a nil return will use sidekiq default
  sidekiq_retry_in do |count, exception, _jobhash|
    case exception
    when HmrcInterface::TryAgain
      count * 5 # i.e. 5, 10, 15, 20, 25, ... seconds
    when HmrcInterface::IncompleteResult
      Rails.logger.error(exception.message)
      :kill
    when HmrcInterface::RequestUnacceptable
      Rails.logger.error(exception.message)
      :kill
    end
  end

  # callback executes just before moving the job to the deadset
  sidekiq_retries_exhausted do |job, _ex|
    Sentry.capture_message <<~ERROR
      "Failed #{job['class']} with #{job['args']}: #{job['error_message']}"
    ERROR
  end
end
