# see https://github.com/sidekiq/sidekiq/wiki/Error-Handling#automatic-job-retry
#
class HmrcInterfaceBaseWorker < ApplicationWorker
  # 5 ~ 8m 24s total wait time
  sidekiq_options retry: 5

  # Override the default interval algorithm between retries
  # so we have control of it and can kill Fatal errors immediately.
  # A nil return will use sidekiq default interval algorithm.
  #
  sidekiq_retry_in do |_count, exception, _jobhash|
    if exception.is_a?(WorkerErrors::TryAgain)
      nil
    elsif exception.is_a?(HmrcInterface::Error::IncompleteResult) ||
          exception.is_a?(HmrcInterface::Error::RequestUnacceptable)
      Rails.logger.error(exception.message)
      :kill
    end
  end

  sidekiq_retries_exhausted do |job, _ex|
    Sentry.capture_message("Failed #{job['class']} for submission #{job['args']}: #{job['error_message']}")
  end
end
