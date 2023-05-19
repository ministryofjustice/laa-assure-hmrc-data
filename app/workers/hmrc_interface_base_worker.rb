# see https://github.com/sidekiq/sidekiq/wiki/Error-Handling#configuration
#
class HmrcInterfaceBaseWorker < ApplicationWorker
  sidekiq_options retry: 10

  # Override the default interval algorithm between retries
  # to shorten it as it should not take more 10 seconds once
  # request submitted, but conncurreny limits may slow it down
  # somewhat.
  #
  # A nil return will use sidekiq default interval algorithm
  #
  # rubocop:disable Style/CaseLikeIf
  sidekiq_retry_in do |count, exception, _jobhash|
    if exception.is_a?(HmrcInterface::TryAgain)
      count * 5 # i.e. 5, 10, 15, 20, 25, ... seconds
    elsif exception.is_a?(HmrcInterface::IncompleteResult)
      Rails.logger.error(exception.message)
      :kill
    elsif exception.is_a?(HmrcInterface::RequestUnacceptable)
      Rails.logger.error(exception.message)
      :kill
    end
  end
  # rubocop:enable Style/CaseLikeIf

  sidekiq_retries_exhausted do |job, _ex|

    # TODO: could use this to mark bulk submission as completed OR uncompleted (or incomplete, partially_completed, ??)
    # when based on whether on or more individual submissions remain in a "processing" or "created" state
    # after retries exhausted.

    Sentry.capture_message("Failed #{job['class']} with #{job['args']}: #{job['error_message']}")
  end
end
