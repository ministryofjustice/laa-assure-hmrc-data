module HmrcInterface
  module ErrorHelper
    delegate :config, to: HmrcInterface

    def handle_request_error(error, http_method = "POST")
      log_and_raise_request_error(
        message: formatted_error_message(error),
        backtrace: error.backtrace&.join("\n"),
        http_method:, # TODO: do we even need this
        http_status: error.respond_to?(:http_status) ? error.http_status : nil # TODO: do we even need this
      )
    end

    def log_and_raise_request_error(
      message:,
      backtrace: nil,
      http_method: "POST",
      http_status: nil
    )
      config.logger.info do
        { message:, backtrace:, http_method:, http_status: }
      end
      raise HmrcInterface::RequestError.new(message, http_status)
    end

    def formatted_error_message(err)
      "#{self.class} received #{err.class}: #{err.message}"
    end

    def detailed_error(url, status, details)
      "URL: #{url}, status: #{status}, details: #{details}"
    end
  end
end
