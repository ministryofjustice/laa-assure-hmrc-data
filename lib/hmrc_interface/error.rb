module HmrcInterface
  class Error < StandardError
    include Nesty::NestedError

    attr_reader :http_status

    def initialize(message, http_status = nil)
      @http_status = http_status
      super(message)
    end
  end

  class Unacceptable < StandardError
  end
end
