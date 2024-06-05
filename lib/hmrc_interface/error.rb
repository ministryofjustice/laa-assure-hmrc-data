module HmrcInterface
  module Error
    class RequestError < StandardError
      include Nesty::NestedError

      attr_reader :http_status

      def initialize(message, http_status = nil)
        @http_status = http_status
        super(message)
      end
    end

    class RequestUnacceptable < StandardError
      def initialize(message = "unacceptable request")
        super
      end
    end

    class IncompleteResult < StandardError
      def initialize(message = "incomplete result")
        super
      end
    end

    class ConfigurationError < StandardError
    end
  end
end
