module HmrcInterface
  module ErrorHelper
    def handle_request_error(error, http_method = "POST")
      log_and_raise_error(
        message: formatted_error_message(error),
        backtrace: error.backtrace&.join("\n"),
        http_method:,
        http_status: error.respond_to?(:http_status) ? error.http_status : nil,
      )
    end

    # TDOD: inject logger from config
    def log_and_raise_error(message:, backtrace: nil, http_method: "POST", http_status: nil)
      Rails.logger.info { { message:, backtrace:, method: http_method, http_status: } }
      raise HmrcInterface::Error.new(message, http_status)
    end

    def formatted_error_message(err)
      "#{self.class} received #{err.class}: #{err.message}"
    end

    def detailed_error(url, status, details)
      "Unacceptable request: URL: #{url}, status: #{status}, details: #{details}"
    end
  end
end
