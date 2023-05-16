module HmrcInterface
  class RequestError < StandardError
    include Nesty::NestedError

    attr_reader :http_status

    def initialize(message, http_status = nil)
      @http_status = http_status
      super(message)
    end
  end

  class TryAgain < StandardError
    def initialize(message = "still processing...")
      super(message)
    end
  end

  class RequestUnacceptable < StandardError
    def initialize(message = "unacceptable request")
      super(message)
    end
  end

  class IncompleteResult < StandardError
    def initialize(message = "incomplete result")
      super(message)
    end
  end

  class ConfigurationError < StandardError
  end
end
