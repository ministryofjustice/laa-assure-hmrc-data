module WorkerErrors
  class TryAgain < StandardError
    def initialize(message = "still processing...")
      super(message)
    end
  end
end
